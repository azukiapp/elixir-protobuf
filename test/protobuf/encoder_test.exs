defmodule Protobuf.Encoder.Test do
  use Protobuf.Case
  alias Protobuf.Encoder, as: E

  test "fixing nil values to :undefined" do
    mod = def_proto_module "
      message Msg {
        required int32 f1 = 1;
        optional int32 f2 = 2;
      }

      message WithSubMsg {
        required Msg f1 = 1;
      }
    "

    msg = mod.Msg.new(f1: 150)
    assert <<8, 150, 1>> == E.encode(msg, msg.defs)
    assert <<10, 3, 8, 150, 1>> == E.encode(mod.WithSubMsg.new(f1: msg), msg.defs)
  end
end
