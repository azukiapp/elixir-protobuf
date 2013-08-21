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
    quote do
      main_module = __MODULE__
      fields = unquote(record_fields(fields))
      defrecord :"#{__MODULE__}.#{unquote(name)}", fields do
        @main_module main_module
        def defs do
          @main_module.defs
        end

        def defs(_) do
          @main_module.defs
        end

        def decode(data), do: Decoder.decode(data, new)
        def decode_from(data, record), do: Decoder.decode(data, record)

        unquote(fields_methods(fields))
      end
    end
  end

  defp record_fields(fields) do
    lc Field[name: name, occurrence: occurrence] inlist fields do
      {name, case occurrence do
        :repeated -> []
        _ -> nil
      end}
    end
  end

  defp fields_methods(fields) do
    contents = lc Field[name: name, rnum: rnum, occurrence: occurrence] inlist fields do
      index = rnum - 1
      extra_content = []
      if occurrence == :repeated do
        extra_content = quote do
          value = (elem(record, unquote(index)) || []) ++ [value]
        end
      end
      quote do
        def update_by_index(unquote(index), value, record) do
          unquote(extra_content)
          :erlang.apply(record, unquote(name), [value])
        end
      end
    end

    contents = contents ++ lc Field[name: name, type: {:enum, mod}] inlist fields do
      quote do
        defoverridable [{unquote(name), 2}]
        def unquote(name)(value, record) when is_atom(value) do
          super(value, record)
        end

        def unquote(name)(value, record) do
          unquote(name)(:"#{@main_module}.#{unquote(mod)}".atom(value), record)
        end
      end
    end

    contents ++ [quote do
      def update_by_index(_, _, record), do: record
    end]
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

