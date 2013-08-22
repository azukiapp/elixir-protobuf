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

  test "decode msg with enum field" do
    mod = def_proto_module "message M1 {
      enum e { v1 = 100; v2 = 150; }
      required e f1 = 1;
    }"

    assert {mod.M1, :v2} == D.decode(<<8,150,1>>, mod.M1)
  end

  test "decode msg with negative enum value" do
    mod = def_proto_module "message M1 {
      enum e { v1 = 100; v2 = -2; }
      required e f1 = 1;
    }"

    assert {mod.M1, :v2} == D.decode(<<8,254,255,255,255,15>>, mod.M1)
  end
end
