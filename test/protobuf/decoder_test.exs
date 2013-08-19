defmodule Protobuf.Decoder.Test do
  use Protobuf.Case
  alias Protobuf.Decoder

  test :read_variant do
    Gpb.compile_tmp_proto "message Msg {
      required uint32 field1 = 1;
      required int64  field2 = 2;
      required string name   = 3;
      optional int32 idade   = 4;
      required string email  = 5;
    }", fn mod ->
      msg = {:Msg, 500000, 2000, "João", 18, "joao@example.com"}
      str = mod.encode_msg(msg)

      assert msg == Decoder.decode(str, :Msg)
    end
  end
end
