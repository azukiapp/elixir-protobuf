defmodule ProtobufTest do
  use Protobuf.Case

  test "auxiliar compile test function" do
    compile_tmp_proto "message Msg { required uint32 field1 = 1; }\n", fn mod ->
      msg = {:Msg, 10}
      assert <<8, 10>> == mod.encode_msg(msg)
      assert msg == mod.decode_msg(mod.encode_msg(msg), :Msg)
    end
  end

  test :read_variant do
    compile_tmp_proto "message Msg {
      required uint32 field1 = 1;
      required int64 field2 = 2;
      required string name   = 3;
      optional int32 idade  = 4;
      required string email  = 5;
    }", fn mod ->
      msg = {:Msg, 500000, 2000, "Éverton", 18, "nuxlli@gmail.com"}
      IO.inspect({:stream, stream = mod.encode_msg(msg)})
      IO.inspect({:msg_gpb, mod.decode_msg(stream, :Msg)})
      IO.inspect({:msg_epb, Protobuf.Decoder.decode(stream, :Msg)})
    end
  end
end
