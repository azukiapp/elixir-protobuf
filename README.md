# Elixir Protobuf

[![wercker status](https://app.wercker.com/status/d8f1feca0e7f89458088dcfd8feb4882/m "wercker status")](https://app.wercker.com/project/bykey/d8f1feca0e7f89458088dcfd8feb4882)

Is a tool for define records from a [Google Protocol Buffer](https://code.google.com/p/protobuf/) definitions files.

## Features

Yet:

* Load protobuf on file or string;
* Respects the namespace of messages;
* Allows you to specify which modules should be loaded in the definition of records;
* Uses the [gpb](https://github.com/tomas-abrahamsson/gpb) to parse;

Still to come:

* Support to importing definitions;
* Its own version of encode and decode (for now uses the gpb)

## Examples

Defining the records from a string:
```elixir
defmodule Messages do
  use Protobuf, "
    message Msg {
      message SubMsg {
        required uint32 value = 1;
      }

      enum Version {
        V1 = 1;
        V2 = 2;
      }

      required Version version = 2;
      optional SubMsg sub = 1;
    }
  "
end
```

Using the definition in iex:
```elixir
iex> msg = Messages.Msg.new(version: :'V2')
Messages.Msg[version: :V2, sub: nil]
iex> msg.encode
<<16, 2>>
iex> msg = msg.sub Messages.Msg.SubMsg.new(value: 10)
Messages.Msg[version: :V2, sub: Messages.Msg.SubMsg[value: 10]]
iex> msg.encode
<<16, 2, 10, 2, 8, 10>>
iex> Messages.Msg.decode(msg.encode)
Messages.Msg[version: :V2, sub: Messages.Msg.SubMsg[value: 10]]
```

## Define from a file

```elixir
defmodule Messages do
  use Protobuf, from: Path.expand("../proto/messages.proto", __DIR__)
end
```

## Use in records

```elixir
defmodule Messages do
  use Protobuf, "
    message Msg {
      enum Version {
        V1 = 1;
        V2 = 1;
      }
      required Version v = 1;
    }
  "

  defmodule MsgHelpers do
    defmacro __using__(_opts) do
      quote do
        Record.import __MODULE__, as: :msg

        def new_v1 do
          msg(v: :V1)
        end
      end
    end
  end

  use_in "Msg", MsgHelpers
end
```

```elixir
iex> Messages.Msg.new_v1
Messages.Msg[v: :V1]
```

## License

"Azuki" and the Azuki logo are copyright (c) 2013 Azuki Serviços de Internet LTDA..

Elixir Protobuf source code is released under Apache 2 License.

Check LEGAL and LICENSE files for more information.


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/azukiapp/elixir-protobuf/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

