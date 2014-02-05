defmodule Protobuf.DefineMessage do
  @moduledoc false

  alias Protobuf.Decoder
  alias Protobuf.Encoder

  defrecord :field, Record.extract(:field, from_lib: "gpb/include/gpb.hrl")

  def def_message(name, fields) do
    quote do
      root   = __MODULE__
      fields = unquote(record_fields(fields))
      use_in = @use_in[unquote(name)]

      defrecord unquote(name), fields do
        @root root

        unquote(encode_decode(name))
        unquote(fields_methods(fields))
        unquote(meta_information)

        if use_in != nil do
          Module.eval_quoted(__MODULE__, use_in, [{:Msg, Msg}], __ENV__)
        end
      end
    end
  end

  defp meta_information do
    quote do
      # Global messages defs information
      def defs(_ // nil) do
        @root.defs
      end

      # Field by field defs information
      def defs(:field, _), do: nil
      def defs(:field, field, _) do
        defs(:field, field)
      end
    end
  end

  defp encode_decode(name) do
    quote do
      def decode(data), do: Decoder.decode(data, __MODULE__)

      def encode(unquote(name)[] = record) do
        Encoder.encode(record, defs)
      end
    end
  end

  defp record_fields(fields) do
    lc :field[name: name, occurrence: occurrence] inlist fields do
      {name, case occurrence do
        :repeated -> []
        _ -> nil
      end}
    end
  end

  defp fields_methods(fields) do
    lc :field[name: name, fnum: fnum] = field inlist fields do
      quote do
        def defs(:field, unquote(fnum)), do: unquote(Macro.escape(field))
        def defs(:field, unquote(name)), do: defs(:field, unquote(fnum))
      end
    end
  end
end
