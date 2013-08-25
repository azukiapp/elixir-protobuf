defmodule Protobuf.Encoder do
  def encode(msg, defs) do
    msg = fix_undefined(msg)
    :gpb.encode_msg(msg, defs)
  end

  defp fix_undefined(msg) do
    Enum.reduce(msg.__record__(:fields), msg, fn
      {field, _}, msg ->
        original = apply(msg, field, [])
        fixed    = fix_value(original)
        if original != fixed do
          apply(msg, field, [fixed])
        else
          msg
        end
    end)
  end

  defp fix_value(nil), do: :undefined

  defp fix_value(values) when is_list(values) do
    lc value inlist values do
      fix_value(value)
    end
  end

  defp fix_value(value) when is_record(value) do
    fix_undefined(value)
  end

  defp fix_value(value), do: value
end
