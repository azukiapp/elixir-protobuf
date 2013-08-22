defmodule Protobuf.Decoder do
  use Bitwise, only_operators: true

  # Decode with record/module
  def decode(bytes, record) do
    fix_values :gpb.decode_msg(bytes, record, record.defs)
  end

  defp fix_values(msg) do
    Enum.reduce(msg.__record__(:fields), msg, fn
      {field, default}, msg ->
        value = apply(msg, field, [])
        if value == :undefined do
          apply(msg, field, [default])
        else
          case msg.defs(:field, field) do
            :field[type: :string] ->
              apply(msg, field, [ :unicode.characters_to_binary(value) ])
            _ ->
              msg
          end
        end
    end)
  end

  def varint(bytes) do
    :gpb.decode_varint(bytes)
  end
end
