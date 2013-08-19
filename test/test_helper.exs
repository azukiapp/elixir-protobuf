Code.require_file "./utils/gpb_compile_helper.exs", __DIR__

ExUnit.start

defmodule Protobuf.Case do
  use ExUnit.CaseTemplate

  using _ do
    quote do
      import unquote(__MODULE__)
      alias GpbCompileHelper, as: Gpb
    end
  end
end
