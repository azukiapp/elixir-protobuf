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
    decode(stream, {message})
  end

  def decode(<<>>, message), do: message

  def decode(stream, message) do
    {tag, wire_type, stream} = read_key(stream)
    {field, stream} = case wire_type do
      0 -> read_variant(stream)
      1 -> read_fixed(8, stream)
      2 -> read_lenght_delimited(stream)
      3 -> raise "Group is deprecated"
      4 -> raise "Group is deprecated"
      5 -> read_fixed(4, stream)
    end
    decode(stream, add_element(field, tag, message))
  end

  def add_element(field, tag, message) when tag <= size(message) do
    insert_elem(message, tag, field)
  end

  def add_element(field, tag, message) do
    message = insert_elem(message, size(message), :undefined)
    add_element(field, tag, message)
  end

  def read_key(stream) do
    {bits, stream} = read_variant(stream)
    {bits >>> 3, bits &&& 0x07, stream}
  end

  def read_variant(bytes) do
    read_variant(bytes, 0, 0)
  end

  def read_variant(<< 1 :: 1, x :: 7, rest :: binary >>, n, acc) do
    read_variant(rest, n + 7, acc ||| x <<< n)
  end

  def read_variant(<< 0 :: 1, x :: 7, rest :: binary >>, n, acc) do
    {acc ||| x <<< n, rest}
  end

  def read_fixed(lenght, stream) do
    IO.inspect({:read_fixed, lenght})
    << bytes :: [binary, size(lenght)], rest :: binary >> = stream
    { bytes, rest }
  end

  def read_lenght_delimited(stream) do
    {lenght, stream} = read_variant(stream)
    read_fixed(lenght, stream)
  end
end
