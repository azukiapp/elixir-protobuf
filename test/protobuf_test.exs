defmodule ProtobufTest do
  use Protobuf.Case

  test "auxiliar compile test function" do
    compile_tmp_proto "message Msg { required uint32 field1 = 1; }\n", fn mod ->
      msg = {:Msg, 10}
      assert <<8, 10>>  == mod.encode_msg(msg)
      assert msg == mod.decode_msg(mod.encode_msg(msg), :Msg)
    end
  end
end
