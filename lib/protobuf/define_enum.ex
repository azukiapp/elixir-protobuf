defmodule Protobuf.DefineEnum do
  @moduledoc false

  def def_enum(name, values) do
    contents = lc {atom, value} inlist values do
      quote do
        def value(unquote(atom)), do: unquote(value)
        def atom(unquote(value)), do: unquote(atom)
      end
    end
    quote do
      defmodule unquote(name) do
        unquote(contents)
        def value(_), do: nil
        def atom(_), do: nil
      end
    end
  end
end
