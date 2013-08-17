ExUnit.start

defrecord :field, Record.extract(:field, from_lib: "gpb/include/gpb.hrl")

defmodule Protobuf.Case do
  use ExUnit.CaseTemplate

  using _ do
    quote do
      import unquote(__MODULE__)
    end
  end

  def compile_tmp_proto(msgs, options // [], module // find_unused_module, func) do
    {:ok, defs} = Protobuf.Parse.parse_string(msgs, options)
    options = [:binary | options]

    {:ok, ^module, module_binary} = :gpb_compile.msg_defs(module, defs, options)
    :code.load_binary(module, '<nofile>', module_binary)

    func.(module)
    unload(module)
  end

  defp unload(module) do
    :code.purge(module)
    :code.delete(module)
  end

  defp find_unused_module(n // 1) do
    mod_name_candidate = :'protobuf-test-tmp-#{n}'
    case :code.is_loaded(mod_name_candidate) do
      false -> mod_name_candidate
      true  -> find_unused_module(n + 1)
    end
  end
end
