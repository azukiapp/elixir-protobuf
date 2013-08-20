defmodule ProtobufTest do
  use Protobuf.Case

  defmacrop def_proto_module(value) do
    quote do
      {:module, mod, _, _} = defmodule mod_temp do
        use Protobuf, unquote(value)
      end; mod
    end
  end

  defp mod_temp(n // 1) do
    mod_candidate = :"#{__MODULE__}.Test_#{n}"
    case :code.is_loaded(mod_candidate) do
      false -> mod_candidate
      _ -> mod_temp(n + 1)
    end
  end

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
end
