defmodule Protobuf.Decoder do
  use Bitwise, only_operators: true

  @wire_types [
    varint: 0,
    fixed64: 1,
    lenght_delimited: 2,
    start_group: 3,
    end_group: 4,
    fixed32: 5
  ]

  def decode(bytes, message) do
    decode(bytes, message, false)
  end

  def decode(bytes, message, debug) when is_atom(message) do
    decode(bytes, message.new, debug)
  end

  def decode(<<>>, message, _), do: message

  def decode(bytes, message, debug) do
    {tag, wire_type, bytes} = read_key(bytes)
    {value, bytes} = case wire_type do
      0 -> varint(bytes)
      1 -> read_fixed(8, bytes)
      2 -> read_lenght_delimited(bytes)
      3 -> raise "Group is deprecated"
      4 -> raise "Group is deprecated"
      5 -> read_fixed(4, bytes)
    end
    if debug do
      IO.inspect(
        message: message,
        tag: tag,
        wire_type: wire_type,
        value: value,
        rest: bytes
      )
    end
    value = decode_field(value, message.defs(:field, tag))
    decode(bytes, message.update_by_tag(tag, value), debug)
  end

  defp decode_field(data, :field[type: {:enum, _}]) do
    decode_field(data, :int32)
  end

  defp decode_field(data, :field[type: {:msg, ns}]) do
    decode(data, ns)
  end

  defp decode_field(data, :field[type: type]) do
    decode_field(data, type)
  end

  defp decode_field(data, type) do
    case type do
      :int32 ->
        << data :: [signed, size(32)] >> = << data :: 32 >>
        data
      :bool ->
        data == 1
      :float ->
        << data :: [little, float, size(32)] >> = data
        data
      :double ->
        << data :: [little, float, size(64)] >> = data
        data
        #<<N:32/little-float, Rest/binary>> = Bin,
        #{N, Rest}
      _ -> data
    end
  end

  def read_key(bytes) do
    {bits, bytes} = varint(bytes)
    {bits >>> 3, bits &&& 0x07, bytes}
  end

  def varint(bytes) do
    :gpb.decode_varint(bytes)
  end

  def read_fixed(lenght, bytes) do
    << bytes :: [binary, size(lenght)], rest :: binary >> = bytes
    { bytes, rest }
  end

  def read_lenght_delimited(bytes) do
    {lenght, bytes} = varint(bytes)
    read_fixed(lenght, bytes)
  end
end
