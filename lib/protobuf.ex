defmodule Protobuf do
  import Protobuf.Parse

  defrecord Field, Record.extract(:field, from_lib: "gpb/include/gpb.hrl")

  defmacro __using__(opts) do
    parse_and_generate(case opts do
      << string :: binary >> -> string
      from: file ->
        {file, []} = Code.eval_quoted(file, [], __CALLER__)
        File.read!(file)
    end)
  end

  defp parse_and_generate(define, _opts // []) do
    {:ok, msgs} = parse(define, [field: Field])

    lc {{item_type, item_name}, fields} inlist msgs do
      case item_type do
        :msg  -> record(item_name, fields)
        :enum -> enum_mod(item_name, fields)
      end
    end
  end

  defp record(record_name, fields) do
    fields = lc Field[name: name] inlist fields do
      {name, :undefined}
    end
    quote do
      defrecord :"#{__MODULE__}.#{unquote(record_name)}", unquote(fields)
    end
  end

  defp enum_mod(enum_name, values) do
    contents = lc {atom, value} inlist values do
      quote do
        def value(unquote(atom)), do: unquote(value)
        def atom(unquote(value)), do: unquote(atom)
      end
    end
    quote do
      defmodule :"#{__MODULE__}.#{unquote(enum_name)}" do
        unquote(contents)
      end
    end
  end
end

