defmodule Protobuf do
  import Protobuf.Parse
  alias Protobuf.Decoder

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

    quotes = lc {{item_type, item_name}, fields} inlist msgs do
      case item_type do
        :msg  -> message(item_name, fields)
        :enum -> enum(item_name, fields)
      end
    end

    quotes ++ [quote do
      def defs do
        unquote(Macro.escape(msgs, unquote: true))
      end
    end]
  end

  defp message(name, fields) do
    contents = lc Field[fnum: fnum, occurrence: occurrence] inlist fields do
      extra_content = case occurrence do
        :repeated -> quote do
          value = (elem(record, unquote(fnum)) || []) ++ [value]
        end
        _ -> []
      end
      quote do
        def update_by_index(unquote(fnum), value, record) do
          unquote(extra_content)
          set_elem(record, unquote(fnum), value)
        end
      end
    end

    contents = contents ++ [quote do
      def update_by_index(_, _, record), do: record
    end]

    fields = lc Field[name: name, occurrence: occurrence] inlist fields do
      {name, case occurrence do
        :repeated -> []
        _ -> nil
      end}
    end

    quote do
      main_module = __MODULE__
      defrecord :"#{__MODULE__}.#{unquote(name)}", unquote(fields) do
        @main_module main_module
        def defs do
          @main_module.defs
        end

        def defs(_) do
          @main_module.defs
        end

        def decode(data), do: Decoder.decode(data, new)
        def decode_from(data, record), do: Decoder.decode(data, record)

        unquote(contents)
      end
    end
  end

  defp enum(name, values) do
    contents = lc {atom, value} inlist values do
      quote do
        def value(unquote(atom)), do: unquote(value)
        def atom(unquote(value)), do: unquote(atom)
      end
    end
    quote do
      defmodule :"#{__MODULE__}.#{unquote(name)}" do
        unquote(contents)
      end
    end
  end
end

