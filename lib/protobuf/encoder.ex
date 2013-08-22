defmodule Protobuf.Encoder do
  def encode(msg, defs) do
    msg = fix_undefined(msg)
    :gpb.encode_msg(msg, defs)
  end

  defp fix_undefined(msg) do
    Enum.reduce(msg.__record__(:fields), msg, fn
      {field, _}, msg ->
        value = apply(msg, field, [])
        cond do
          value == nil -> apply(msg, field, [:undefined])
          is_record(value) -> apply(msg, field, [fix_undefined(value)])
          true -> msg
        end
    end)
  end
end
