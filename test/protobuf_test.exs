defmodule ProtobufTest do
  use Protobuf.Case

  test "define records in namespace" do
    mod = def_proto_module "
       message Msg1 {
         required uint32 f1 = 1;
       }

       message Msg2 {
         required string f1 = 1;
       }
    "
    msg = mod.Msg1.new(f1: 1)
    assert is_record(msg, mod.Msg1)
    assert 1 == msg.f1

    msg = mod.Msg2.new(f1: "foo")
    assert is_record(msg, mod.Msg2)
    assert "foo" == msg.f1
  end

  test "set default value for nil is optional" do
    mod = def_proto_module "message Msg { optional uint32 f1 = 1; }"
    msg = mod.Msg.new()
    assert nil == msg.f1
  end

  test "set default value for [] is repeated" do
    mod = def_proto_module "message Msg { repeated uint32 f1 = 1; }"
    msg = mod.Msg.new()
    assert [] == msg.f1
  end

  test "define a record in subnamespace" do
    mod = def_proto_module "
      message Msg {
        message SubMsg {
          required uint32 f1 = 1;
        }

        required SubMsg f1 = 1;
      }
    "

    msg = mod.Msg.SubMsg.new(f1: 1)
    assert is_record(msg, mod.Msg.SubMsg)

    msg = mod.Msg.new(f1: msg)
    assert is_record(msg.f1, mod.Msg.SubMsg)
  end

  test "define enum information module" do
    mod = def_proto_module "
      enum Version {
        V0_1 = 1;
        V0_2 = 2;
      }
      message Msg {
        enum MsgType {
          START = 1;
          STOP  = 2;
        }
        required MsgType type = 1;
        required Version version = 1;
      }
    "

    assert {:file, '#{__FILE__}'} == :code.is_loaded(mod.Version)
    assert {:file, '#{__FILE__}'} == :code.is_loaded(mod.Msg.MsgType)

    assert 1 == mod.Version.value(:V0_1)
    assert 1 == mod.Msg.MsgType.value(:START)

    assert :V0_2  == mod.Version.atom(2)
    assert :STOP == mod.Msg.MsgType.atom(2)
  end

  test "support to define from a file" do
    defmodule ProtoFromFile do
      use Protobuf, from: Path.expand("./proto/basic.proto", __DIR__)
    end

    basic = ProtoFromFile.Basic.new(f1: 1)
    assert is_record(basic, ProtoFromFile.Basic)
  end

  test "set a method proto to get proto defs" do
    mod  = def_proto_module "message Msg { optional uint32 f1 = 1; }"
    defs = [{{:msg, :Msg}, [{Protobuf.Field, :f1, 1, 2, :uint32, :optional, []}]}]
    assert defs == mod.defs
    assert defs == mod.Msg.defs
    assert defs == mod.Msg.new.defs
  end

  test "implement method decode" do
    mod = def_proto_module "message Msg { optional uint32 f1 = 1; }"
    assert is_record(mod.Msg.decode(<<>>), mod.Msg)
    assert is_record(mod.Msg.new.decode_from(<<>>), mod.Msg)
  end
end
