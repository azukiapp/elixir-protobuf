defmodule Protobuf do
  import Protobuf.Parse
  alias Protobuf.Decoder

  defrecord :field, Record.extract(:field, from_lib: "gpb/include/gpb.hrl")

  defmacro __using__(opts) do
    parse_and_generate(__CALLER__.module, case opts do
      << string :: binary >> -> string
      from: file ->
        {file, []} = Code.eval_quoted(file, [], __CALLER__)
        File.read!(file)
    end)
  end

  defp parse_and_generate(ns, define, _opts // []) do
    msgs = parse!(define)

    # Fixing namespaces
    msgs = fix_defs_ns(msgs, ns)

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
      defrecord unquote(name), fields do
        @main_module main_module

        def decode(data), do: Decoder.decode(data, new)
        def decode_from(data, record), do: Decoder.decode(data, record)

        unquote(fields_methods(fields))

        # Messages defs information
        def defs(_ // nil) do
          @main_module.defs
        end

        # Fields defs information
        def defs(:field, _), do: nil
        def defs(:field, field, _) do
          defs(:field, field)
        end
      end
    end
  end

  defp record_fields(fields) do
    lc :field[name: name, occurrence: occurrence] inlist fields do
      {name, case occurrence do
        :repeated -> []
        _ -> nil
      end}
    end
  end

  defp fields_methods(fields) do
    contents = lc :field[name: name, rnum: rnum, fnum: fnum, occurrence: occurrence] = field inlist fields do
      extra_content = []
      if occurrence == :repeated do
        extra_content = quote do
          unless is_list(value) do
            value = (elem(record, unquote(rnum - 1)) || []) ++ [value]
          end
        end
      end
      quote do
        def update_by_tag(unquote(fnum), value, record) do
          unquote(extra_content)
          :erlang.apply(record, unquote(name), [value])
        end

        def defs(:field, unquote(fnum)), do: unquote(Macro.escape(field))
        def defs(:field, unquote(name)), do: defs(:field, unquote(fnum))
      end
    end

    #IO.puts(Macro.to_string(contents))

    contents = contents ++ lc :field[name: name, type: {:enum, mod}] inlist fields do
      quote do
        defoverridable [{unquote(name), 2}]
        def unquote(name)(value, record) when is_atom(value) do
          super(value, record)
        end

        def unquote(name)(value, record) do
          unquote(name)(unquote(mod).atom(value), record)
        end
      end
    end

    contents ++ [quote do
      def update_by_tag(_, _, record), do: record
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
      defmodule unquote(name) do
        unquote(contents)
        def value(_), do: nil
        def atom(_), do: nil
      end
    end
  end

  defp fix_defs_ns(defs, ns) do
    lc {{type, name}, fields} inlist defs do
      {{type, :"#{ns}.#{name}"}, fix_fields_ns(type, fields, ns)}
    end
  end

  defp fix_fields_ns(:msg, fields, ns) do
    Enum.map(fields, fix_field_ns(&1, ns))
  end

  defp fix_fields_ns(_, fields, _), do: fields

  defp fix_field_ns(:field[type: {type, name}] = field, ns) do
    field.type { type, :"#{ns}.#{name}" }
  end

  defp fix_field_ns(:field[] = field, _ns) do
    field
  end
end

