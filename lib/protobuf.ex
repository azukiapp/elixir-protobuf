defmodule Protobuf do
  import Protobuf.Parse

  alias Protobuf.Decoder
  alias Protobuf.Encoder

  defrecord :field, Record.extract(:field, from_lib: "gpb/include/gpb.hrl")

  defmacro __using__(opts) do
    defs = case opts do
      << string :: binary >> -> string
      from: file ->
        {file, []} = Code.eval_quoted(file, [], __CALLER__)
        File.read!(file)
    end

    quote do
      import unquote(__MODULE__), only: [extra_block: 2]

      @defs unquote(defs)
      Module.register_attribute __MODULE__, :extra_body, accumulate: true

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    module = __CALLER__.module
    quote do
      contents = unquote(__MODULE__).parse_and_generate(unquote(module), @defs)
      Module.eval_quoted __MODULE__, contents, [], __ENV__
    end
  end

  defmacro extra_block(module, do: block) do
    block  = Macro.escape(block, unquote: true)
    module = :"#{__CALLER__.module}.#{module}"
    quote do
      @extra_body {unquote(module), unquote(block)}
    end
  end

  def parse_and_generate(ns, define, _opts // []) do
    msgs = parse!(define)

    # Fixing namespaces
    msgs = fix_defs_ns(msgs, ns)

    quotes = lc {{item_type, item_name}, fields} inlist msgs do
      case item_type do
        :msg  -> message(item_name, fields)
        :enum -> enum(item_name, fields)
        # Skips any
        _ -> []
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
      fields      = unquote(record_fields(fields))
      extra_body  = @extra_body[unquote(name)]

      defrecord unquote(name), fields do
        @main_module main_module

        def decode(data), do: Decoder.decode(data, __MODULE__)

        def encode(unquote(name)[] = record) do
          Encoder.encode(record, defs)
        end

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

        Module.eval_quoted(__MODULE__, extra_body, [], __ENV__)
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
    lc :field[name: name, fnum: fnum] = field inlist fields do
      quote do
        def defs(:field, unquote(fnum)), do: unquote(Macro.escape(field))
        def defs(:field, unquote(name)), do: defs(:field, unquote(fnum))
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

