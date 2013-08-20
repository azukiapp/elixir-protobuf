defmodule Protobuf.Parse do

  def parse(msgs), do: parse(msgs, [])

  def parse(defs, options) when is_list(defs) do
    {:ok, defs} = :gpb_parse.post_process(defs, options)

    if type = Keyword.get(options, :field) do
      defs = lc {msg, fields} inlist defs do
        case msg do
          {:msg, _} ->
            {msg, lc field inlist fields do
              delete_elem(field, 0) |> insert_elem(0, type)
            end}
          _ -> {msg, fields}
        end
      end
    end

    {:ok, defs}
  end

  def parse(string, options) do
    {:ok, tokens, _} = :gpb_scan.string('#{string}')
    {:ok, defs} = :gpb_parse.parse(tokens ++ [{:'$end', 999}])
    parse(defs, options)
  end
end
