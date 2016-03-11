% Copyright (c) 2016, Yuce Tekol <yucetekol@gmail.com>.
% All rights reserved.

% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:

% * Redistributions of source code must retain the above copyright
%   notice, this list of conditions and the following disclaimer.

% * Redistributions in binary form must reproduce the above copyright
%   notice, this list of conditions and the following disclaimer in the
%   documentation and/or other materials provided with the distribution.

% * The names of its contributors may not be used to endorse or promote
%   products derived from this software without specific prior written
%   permission.

% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
% A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
% OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
% LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
% DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
% THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

-module(yes_msg).

-export([encode/1,
         encode/2,
         decode/1]).
         
-define(NL, "\r\n").
-define(SEP, ";").

-type decoded_message() :: binary() | {binary(), binary()}.

%% == API

-spec encode(MsgName :: binary()) ->
    {ok, Msg :: binary()} | {error, encode_error}.
encode(MsgName) when byte_size(MsgName) > 0 ->
    case msg_name_valid(MsgName) of
        true -> {ok, <<MsgName/binary, ?NL>>};
        _ -> {error, encode_error}
    end.
    
-spec encode(MsgName :: binary(), Payload :: binary()) ->
    {ok, Msg :: binary()} | {error, Reason :: term()}.
encode(MsgName, Payload) when byte_size(MsgName) > 0->
    case msg_name_valid(MsgName) of
        true ->
            BinLen = integer_to_binary(byte_size(Payload)),
            {ok, <<MsgName/binary, ?SEP, BinLen/binary, ?NL, Payload/binary, ?NL>>};
        _ -> {error, encode_error}
    end.
    
-spec decode(Bin :: binary()) ->
    {ok, Messages :: [decoded_message()], Remaining :: binary()} |
    {error, decode_error}.    
decode(Bin) ->
    try decode_msg(Bin, [], <<>>) of
        M -> M
    catch
        error:badarg ->
            {error, decode_error}
    end.

%% == Internal

msg_name_valid(MsgName) ->
    case binary:match(MsgName, [<<";">>, <<"\r">>, <<"\n">>]) of
        nomatch -> true;
        _ -> false
    end.

decode_msg(<<>>, MsgAcc, Remaining) ->
    {ok, lists:reverse(MsgAcc), Remaining};

decode_msg(Bin, MsgAcc, _) ->
    case decode_msg_flip(Bin) of
        remaining ->
            decode_msg(<<>>, MsgAcc, Bin);
        {Op, undefined, NewBin} ->
            decode_msg(NewBin, [Op | MsgAcc], <<>>);
        {Op, PayloadSize, NewBin} ->
            case decode_msg_flop(NewBin, PayloadSize) of
                remaining ->
                    decode_msg(<<>>, MsgAcc, Bin);
                {Payload, Rest} ->
                    Msg = {Op, Payload},
                    decode_msg(Rest, [Msg | MsgAcc], <<>>)
            end
    end.

decode_msg_flip(Bin) ->
    case binary:match(Bin, <<?NL>>) of
        nomatch ->
            remaining;
        {Pos, 2} ->
            BinSize = byte_size(Bin),
            FlipBin = binary:part(Bin, {0, Pos}),
            {Op, PayloadSize} = extract_flip(FlipBin),
            Rest = binary:part(Bin, {Pos + 2, BinSize - (Pos + 2)}),
            {Op, PayloadSize, Rest}
    end.

decode_msg_flop(Bin, PayloadSize) ->
    BinSize = byte_size(Bin),
    case BinSize >= (PayloadSize + 2) of
        true ->
            Payload = binary:part(Bin, {0, PayloadSize}),
            Rest = binary:part(Bin, {PayloadSize + 2, BinSize - (PayloadSize + 2)}),
            {Payload, Rest};
        _ ->
            remaining
    end.

extract_flip(Bin) ->
    case binary:split(Bin, <<?SEP>>) of
        [Op, BinPayloadSize] ->
            {Op, binary_to_integer(BinPayloadSize)};
        [Op] ->
            {Op, undefined}
    end.


-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

encode_atom_msg_test() ->
    R = encode(<<"OK">>),
    E = {ok, <<"OK\r\n">>},
    ?assertEqual(E, R).

encode_payload_msg_test() ->
    R = encode(<<"watch">>, <<"/tmp/foo">>),
    E = {ok, <<"watch;8\r\n/tmp/foo\r\n">>},
    ?assertEqual(E, R).
    
encode_error_1_test() ->
    R = encode(<<"OK;">>),
    E = {error, encode_error},
    ?assertEqual(E, R).    
    
decode_atom_msg_test() ->
    R = decode(<<"OK\r\n">>),
    E = {ok, [<<"OK">>], <<>>},
    ?assertEqual(E, R).

decode_payload_msg_test() ->
    R = decode(<<"watch;8\r\n/tmp/foo\r\n">>),
    E = {ok, [{<<"watch">>, <<"/tmp/foo">>}], <<>>},
    ?assertEqual(E, R).

decode_many_atom_msgs_test() ->
    R = decode(<<"MSG1\r\nMSG2\r\n">>),
    E = {ok, [<<"MSG1">>, <<"MSG2">>], <<>>},
    ?assertEqual(E, R).

decode_many_atom_msgs_rem_test() ->
    R = decode(<<"MSG1\r\nMSG2">>),
    E = {ok, [<<"MSG1">>], <<"MSG2">>},
    ?assertEqual(E, R).
    
decode_many_payload_msgs_test() ->
    R = decode(<<"MSG1;2\r\nab\r\nMSG2;5\r\nabcde\r\n">>),
    E = {ok, [{<<"MSG1">>, <<"ab">>}, {<<"MSG2">>, <<"abcde">>}], <<>>},
    ?assertEqual(E, R).    

decode_many_payload_msgs_rem_test() ->
    R = decode(<<"MSG1;2\r\nab\r\nMSG2;5\r\nabc">>),
    E = {ok, [{<<"MSG1">>, <<"ab">>}], <<"MSG2;5\r\nabc">>},
    ?assertEqual(E, R).    

decode_error_1_test() ->
    R = decode(<<"MSG;foo\r\nbar\r\n">>),
    E = {error, decode_error},
    ?assertEqual(E, R).

decode_error_2_test() ->
    R = decode(<<"MSG;;;;foo\r\nbar\r\n">>),
    E = {error, decode_error},
    ?assertEqual(E, R).

decode_error_3_test() ->
    R = decode(<<"\r\nMSG;;;;foo\r\nbar\r\n">>),
    E = {error, decode_error},
    ?assertEqual(E, R).

-endif.