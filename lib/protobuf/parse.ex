defmodule Protobuf.Parse do

  defexception ParseError, error: nil do
    def message(ParseError[error: error]) do
      inspect(error)
    end
  end

  def parse(msgs), do: parse(msgs, [])

  def parse(defs, options) when is_list(defs) do
    :gpb_parse.post_process(defs, options)
  end

  def parse(string, options) do
    case :gpb_scan.string('#{string}') do
      {:ok, tokens, _} ->
        case :gpb_parse.parse(tokens ++ [{:'$end', 999}]) do
          {:ok, defs} ->
            parse(defs, options)
          error ->
            error
        end
      error ->
        error
    end
  end

  def parse!(string, options \\ []) do
    case parse(string, options) do
      {:ok, defs} -> defs
      {:error, error} ->
        raise(ParseError, error: error)
    end
  end
end
