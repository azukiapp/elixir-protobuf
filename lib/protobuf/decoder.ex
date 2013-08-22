defmodule Protobuf.Decoder do
  use Bitwise, only_operators: true

  # Decode with record/module
  def decode(bytes, msg) when is_atom(msg) do
    decode(bytes, msg.new)
  end

  # Decode with record
  def decode(<<>>, message), do: message
  def decode(bytes, message) do
    {tag, wire_type, bytes} = read_key(bytes)

    case message.defs(:field, tag) do
      :field[opts: opts] = field ->
        {value, bytes} = if :packed in opts do
          decode_packed(bytes, field)
        else
          decode_field(bytes, field)
        end
        message = message.update_by_tag(tag, value)
      _ ->
        # skip fields
        #IO.inspect({tag, wire_type, message.__record__(:name) })
        {_, bytes} = skip_field(wire_type, bytes)
    end

    # Next bytes
    decode(bytes, message)
  end

  def varint(bytes) do
    :gpb.decode_varint(bytes)
  end

  # Packed decode
  defp decode_packed(bytes, field) do
    {bytes, rest} = read_lenght_delimited(bytes)
    decode_packed(bytes, field, [], rest)
  end

  defp decode_packed(<<>>, _, values, rest) do
    { values, rest }
  end

  defp decode_packed(bytes, field, values, rest) do
    #IO.inspect({bytes, values, rest, field})
    {value, bytes} = decode_field(bytes, field)
    decode_packed(bytes, field, values ++ [value], rest)
  end

  # Decode msg fields
  defp decode_field(bytes, :field[type: {:msg, ns}]) do
    {value, bytes} = read_lenght_delimited(bytes)
    {decode(value, ns), bytes}
  end

  # Plan field decode
  defp decode_field(bytes, :field[type: {:enum, _}]) do
    decode_type(bytes, :int32)
  end

  defp decode_field( bytes, :field[type: type]) do
    decode_type(bytes, type)
  end

  defp skip_field(wire_type, bytes) do
    case wire_type do
      0 -> varint(bytes)
      1 -> read_fixed(8, bytes)
      2 -> read_lenght_delimited(bytes)
      5 -> read_fixed(4, bytes)
    end
  end

  # Utils
  defp read_key(bytes) do
    {bits, bytes} = varint(bytes)
    {bits >>> 3, bits &&& 0x07, bytes}
  end

  def read_fixed(lenght, bytes) do
    << bytes :: [binary, size(lenght)], rest :: binary >> = bytes
    { bytes, rest }
  end

  def read_lenght_delimited(bytes) do
    {lenght, bytes} = varint(bytes)
    read_fixed(lenght, bytes)
  end

  # Decode by type
  defp decode_type(data, type) do
    case type do
      :string ->
        read_lenght_delimited(data)
      :bytes ->
        read_lenght_delimited(data)
      :int32 ->
        { data, rest } = varint(data)
        << result :: [signed, size(32)] >> = << data :: 32 >>
        { result, rest }
      :bool ->
        { data, rest } = varint(data)
        { data == 1, rest }
      :float ->
        << result :: [little, float, size(32)], rest :: binary >> = data
        { result, rest }
      :double ->
        << result :: [little, float, size(64)], rest :: binary >> = data
        { result, rest }
      _ ->
        { nil, data }
    end
  end
end
