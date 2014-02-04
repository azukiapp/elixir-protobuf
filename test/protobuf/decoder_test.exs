defmodule Protobuf.Decoder.Test do
  use Protobuf.Case
  alias Protobuf.Decoder, as: D

  test "fix :undefined values to nil value" do
    mod = def_proto_module "message Msg {
      optional int32 f1 = 1;
      required int32 f2 = 2;
    }"

    assert {mod.Msg, nil, 150} == D.decode(<<16, 150, 1>>, mod.Msg)
  end

  test "fix repeated values" do
    mod = def_proto_module "message Msg {
      repeated string f1 = 1;
    }"

    bytes = <<10, 3, 102, 111, 111, 10, 3, 98, 97, 114>>
    assert {mod.Msg, ["foo", "bar"] } == D.decode(bytes, mod.Msg)
  end

  test "fixing string values" do
    mod = def_proto_module "message Msg {
      required string f1 = 1;

      message SubMsg {
        required string f1 = 1;
      }

      optional SubMsg f2 = 2;
    }"

    bytes = <<10,11,?a,?b,?c,?\303,?\245,?\303,?\244,?\303,?\266,?\317,?\276>>
    assert {mod.Msg, "abcåäöϾ", nil} == D.decode(bytes, mod.Msg)

    bytes = <<10, 1, 97, 18, 5, 10, 3, 97, 98, 99>>
    assert {mod.Msg, "a", {mod.Msg.SubMsg, "abc"}} == D.decode(bytes, mod.Msg)
  end
end
