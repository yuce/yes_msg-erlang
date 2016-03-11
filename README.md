# yes_msg

Yet another simple message (YES) parser for Erlang.

## Build

    $ rebar3 compile

## Message Format

Messages consist of

1. Name: Consist of an arbitrary number of characters.
Following characters cannot be used in a name: `;`, `\r`, `\n`.
2. (Optional) payload size and payload.

**yes_msg** supports two kinds of messages:

1. Atoms consist of only a message name
2. Messages with payloads

### Atom message

`[Message Name]\r\n`

### Message with payload

`[Message Name];[Payload length]\r\n[Payload]\r\n`

## Usage

Encode an atom message:

```erlang
MsgName = <<"OK">>,
{ok, Msg} = yes_msg:encode(MsgName).
% Msg = <<"OK\r\n">>
```

Encode a message with payload:

```erlang
MsgName = <<"list">>,
MsgPayload = <<"/tmp/yes">>,
{ok, Msg} = yes_msg:encode(MsgName, MsgPayload).
% Msg = <<"list;8\r\n/tmp/yes\r\n">>
```

`yes_msg:encode/1` and `yes_msg:encode/2` return `{ok, EncodedMessage}` on
success and `{error, encode_error}` on encoding failure.

Decode a binary:

```erlang
Binary = <<"list;8\r\n/tmp/yes\r\n">>,
{ok, Messages, Remaining} = yes_msg:decode(Binary).
% Nessages = [{<<"list">>, <<"/tmp/yes">>}]
% Remaining = <<>>
```

`yes_msg:decode/1` return `{ok, MessagesList, RemainingBinary}` on success
and `{error, decode_error}` on decoding failure.

## License

```
Copyright (c) 2016, Yuce Tekol <yucetekol@gmail.com>.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

* The names of its contributors may not be used to endorse or promote
  products derived from this software without specific prior written
  permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```