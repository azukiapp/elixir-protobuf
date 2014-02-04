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
        required Version version = 2;
      }
    "

    assert {:file, '#{__ENV__.file}'} == :code.is_loaded(mod.Version)
    assert {:file, '#{__ENV__.file}'} == :code.is_loaded(mod.Msg.MsgType)

    assert 1 == mod.Version.value(:V0_1)
    assert 1 == mod.Msg.MsgType.value(:START)

    assert :V0_2  == mod.Version.atom(2)
    assert :STOP == mod.Msg.MsgType.atom(2)

    assert nil == mod.Version.atom(-1)
    assert nil == mod.Msg.MsgType.value(:OTHER)
  end

  test "support to define from a file" do
    defmodule ProtoFromFile do
      use Protobuf, from: Path.expand("./proto/basic.proto", __DIR__)
    end

    basic = ProtoFromFile.Basic.new(f1: 1)
    assert is_record(basic, ProtoFromFile.Basic)
  end

  test "define a method to get proto defs" do
    mod  = def_proto_module "message Msg { optional uint32 f1 = 1; }"
    defs = [{{:msg, mod.Msg}, [{:field, :f1, 1, 2, :uint32, :optional, []}]}]
    assert defs == mod.defs
    assert defs == mod.Msg.defs
    assert defs == mod.Msg.new.defs
  end

  test "defined a method defs to get field info" do
    mod  = def_proto_module "message Msg { optional uint32 f1 = 1; }"
    deff = {:field, :f1, 1, 2, :uint32, :optional, []}
    assert deff == mod.Msg.defs(:field, 1)
    assert deff == mod.Msg.defs(:field, :f1)
  end

  test "defined method decode" do
    mod = def_proto_module "message Msg { optional uint32 f1 = 1; }"
    assert is_record(mod.Msg.decode(<<>>), mod.Msg)
  end

  test "extensions skip" do
    mod = def_proto_module "
      message Msg {
        required uint32 f1 = 1;
        extensions 100 to 200;
      }
    "
    assert is_record(mod.Msg.new, mod.Msg)
  end

  test "addiontal method via use_in" do
    defmodule AddViaHelper do
      use Protobuf, "message Msg {
        required uint32 f1 = 1;
      }"

      defmodule MsgHelper do
        defmacro __using__(_opts) do
          quote do
            Record.import __MODULE__, as: :r_msg

            def sub(value, r_msg(f1: f1) = msg) do
              msg.f1(f1 - value)
            end
          end
        end
      end

      use_in :Msg, MsgHelper
    end

    msg = AddViaHelper.Msg.new(f1: 10)
    assert {AddViaHelper.Msg, 5} == msg.sub(5)
  end
end
