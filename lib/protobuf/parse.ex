defmodule Protobuf.Parse do
  def parse_string(string, options // []) do
    {:ok, tokens, _} = :gpb_scan.string('#{string}')
    {:ok, defs} = :gpb_parse.parse(tokens ++ [{:'$end', 999}])
    :gpb_parse.post_process(defs, options)
  end
end
