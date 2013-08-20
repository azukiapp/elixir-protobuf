defmodule Protobuf.Decoder.Test do
  use Protobuf.Case
  alias Protobuf.Decoder, as: D

  defrecord M1, a: nil
  defrecord M2, b: nil
  defrecord M4, x: nil, y: nil

  test "decode varint" do
    assert {0  , <<255>>} == D.varint(<<0, 255>>)
    assert {127, <<255>>} == D.varint(<<127,255>>)
    assert {128, <<255>>} == D.varint(<<128, 1, 255>>)
    assert {150, <<255>>} == D.varint(<<150, 1, 255>>)
  end

  test "decode overly long noncanonical variants" do
    assert {0, <<255>>} == D.varint(<<128, 0, 255>>)
    assert {0, <<255>>} == D.varint(<<128, 128, 128, 128, 0, 255>>)
    assert {1, <<255>>} == D.varint(<<129, 128, 128, 128, 0, 255>>)
    assert {20394, <<255>>} == D.varint(<<170,159,(128+1), 128, 128, 0, 255>>)
  end

  test "skipping unknow fields" do
    mod = def_proto_module "message M1 { optional int32 a = 1; }"

    assert {mod.M1, nil} == D.decode(<<32,150,1>>, mod.M1)   # varint
    assert {mod.M1, nil} == D.decode(<<34,1,1>>, mod.M1)     # legth delimited
    assert {mod.M1, nil} == D.decode(<<37,0,0,0,0>>, mod.M1) # 32bit
    assert {mod.M1, nil} == D.decode(<<33,0,0,0,0,0,0,0,0>>, mod.M1) # 64bit
  end

  test "decode msg simple occurrence" do
    mod = def_proto_module "message M1 { optional int32 a = 1; }"
    assert {mod.M1, nil} == D.decode(<<>>, mod.M1)
    mod = def_proto_module "message M1 { required int32 a = 1; }"
    assert {mod.M1, 150} == D.decode(<<8,150,1>>, mod.M1)
    mod = def_proto_module "message M1 { repeated int32 a = 1; }"
    assert {mod.M1, [150, 151]} == D.decode(<<8, 150, 1, 8, 151, 1>>, mod.M1)
  end

  #test :read_variant do
    #Gpb.compile_tmp_proto "message Msg {
      #required uint32 field1 = 1;
      #required int64  field2 = 2;
      #required string name   = 3;
      #optional int32 idade   = 4;
      #required string email  = 5;
    #}", fn mod ->
      #msg = {:Msg, 500000, 2000, "João", :undefined, "joao@example.com"}
      #str = mod.encode_msg(msg)

      #assert msg == Decoder.decode(str, :Msg)
    #end
  #end
end
