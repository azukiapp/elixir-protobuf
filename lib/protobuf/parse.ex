defmodule Protobuf.Parse do

  #defrecord :field, Record.extract(:field, from_lib: "gpb/include/gpb.hrl")

  def parse(msgs), do: parse(msgs, [])

  def parse(defs, options) when is_list(defs) do
    :gpb_parse.post_process(defs, options)
  end

  def parse(string, options) do
    {:ok, tokens, _} = :gpb_scan.string('#{string}')
    {:ok, defs} = :gpb_parse.parse(tokens ++ [{:'$end', 999}])
    parse(defs, options)
  end
end
