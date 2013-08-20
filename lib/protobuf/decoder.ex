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

  def decode(stream, message) when is_atom(message) do
    decode(stream, message.new)
  end

  def decode(<<>>, message), do: message

  def decode(stream, message) do
    {tag, wire_type, stream} = read_key(stream)
    {value, stream} = case wire_type do
      0 -> varint(stream)
      1 -> read_fixed(8, stream)
      2 -> read_lenght_delimited(stream)
      3 -> raise "Group is deprecated"
      4 -> raise "Group is deprecated"
      5 -> read_fixed(4, stream)
    end
    #IO.inspect({message, value, tag, stream})
    decode(stream, message.update_by_index(tag, value))
  end

  def read_key(stream) do
    {bits, stream} = varint(stream)
    {bits >>> 3, bits &&& 0x07, stream}
  end

  def varint(bytes) do
    varint(bytes, 0, 0)
  end

  def varint(<< 1 :: 1, x :: 7, rest :: binary >>, n, acc) do
    varint(rest, n + 7, acc ||| x <<< n)
  end

  def varint(<< 0 :: 1, x :: 7, rest :: binary >>, n, acc) do
    {acc ||| x <<< n, rest}
  end

  def read_fixed(lenght, stream) do
    << bytes :: [binary, size(lenght)], rest :: binary >> = stream
    { bytes, rest }
  end

  def read_lenght_delimited(stream) do
    {lenght, stream} = varint(stream)
    read_fixed(lenght, stream)
  end
end
