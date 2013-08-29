defmodule Protobuf.Decoder do
  use Bitwise, only_operators: true

  # Decode with record/module
  def decode(bytes, record) do
    fix_msg :gpb.decode_msg(bytes, record, record.defs)
  end

  def varint(bytes) do
    :gpb.decode_varint(bytes)
  end

  defp fix_msg(msg) do
    Enum.reduce(msg.__record__(:fields), msg, fn
      {field, default}, msg ->
        value = apply(msg, field, [])
        if value == :undefined do
          apply(msg, field, [default])
        else
          fix_field(value, msg, msg.defs(:field, field))
        end
    end)
  end

  defp fix_field(value, msg, :field[name: field, type: type, occurrence: occurrence]) do
    case {occurrence, type} do
      {:repeated, _} ->
        value = lc v inlist value, do: fix_value(type, v)
        apply(msg, field, [value])
      {_, :string}   ->
        apply(msg, field, [fix_value(type, value)])
      {_, {:msg, _}} ->
        apply(msg, field, [fix_value(type, value)])
      _ ->
        msg
    end
  end

  defp fix_value(:string, value) do
    :unicode.characters_to_binary(value)
  end

  defp fix_value({:msg, _}, value) do
    fix_msg(value)
  end

  defp fix_value(_, value), do: value
end
