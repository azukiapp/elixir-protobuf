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

  setup_all do
    { :ok, mod: def_proto_module("
      message EnumTest {
        enum e { v1 = 150; v2 = -2; }
        required e f1 = 1;
      }

      message BoolTest {
        required bool f1 = 1;
      }

      message FloatTest {
        required float f1 = 1;
      }

      message DoudleTest {
        required double f1 = 1;
      }

      message StringTest {
        required string f1 = 1;
      }

      message BytesTest {
        required bytes f1 = 1;
      }

      message SubMsgTest {
        message MsgTest {
          required uint32 f1 = 1;
        }
        required MsgTest f1 = 1;
      }

      message SubOptionalMsgTest {
        optional SubMsgTest f1 = 1;
      }

      message ZeroInstancePackedTest {
        repeated int32 f1 = 1;
      }
    ")}
  end

  test "decode msg with enum field", vars do
    mod = vars[:mod]
    assert {mod.EnumTest, :v1} == D.decode(<<8,150,1>>, mod.EnumTest)
  end

  test "decode msg with negative enum value", vars do
    mod = vars[:mod]
    assert {mod.EnumTest, :v2} == D.decode(<<8,254,255,255,255,15>>, mod.EnumTest)
  end

  test "decode msg with bool field", vars do
    mod = vars[:mod]
    assert {mod.BoolTest, true }  == D.decode(<<8,1>>, mod.BoolTest)
    assert {mod.BoolTest, false}  == D.decode(<<8,0>>, mod.BoolTest)
  end

  test "decode msg with float field", vars do
    mod = vars[:mod].FloatTest
    assert {mod, 1.125} == D.decode(<<13,0,0,144,63>>, mod)
  end

  test "decode msg with double field", vars do
    mod = vars[:mod].DoudleTest
    assert {mod, 1.125} == D.decode(<<9,0,0,0,0,0,0,242,63>>, mod)
  end

  test "decode msg with string field", vars do
    mod  = vars[:mod].StringTest
    data = <<10,11,?a,?b,?c,?\303,?\245,?\303,?\244,?\303,?\266,?\317,?\276>>
    assert {mod, "abcåäöϾ"} == D.decode(data, mod)
  end

  test "decode msg with bytes field", vars do
    mod  = vars[:mod].BytesTest
    assert {mod, <<0,0,0,0>>} == D.decode(<<10,4,0,0,0,0>>, mod)
  end

  test "decode msg with sub msg field", vars do
    mod  = vars[:mod]
    msg  = {mod.SubMsgTest, {mod.SubMsgTest.MsgTest, 150}}
    assert msg == D.decode(<<10,3, 8,150,1>>, mod.SubMsgTest)
  end

  test "decode msg with optional nonpresent sub msg field", vars do
    mod  = vars[:mod]
    msg  = {mod.SubOptionalMsgTest, nil}
    assert msg == D.decode(<<>>, mod.SubOptionalMsgTest)
  end

  test "decode zero instances of packed variants", vars do
    rmsg = vars[:mod].ZeroInstancePackedTest
    assert {rmsg, []} == D.decode(<<>>, rmsg)
  end
end
