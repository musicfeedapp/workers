defmodule Requesters.Link do
  def id(link, patterns), do: _id(link, nil, patterns)

  defp _id(link, nil, [head | tail]) do
    case Regex.scan(head, link) do
      [[_nothing, id]] -> _id(link, id, tail)
      _nothing -> _id(link, nil, tail)
    end
  end
  defp _id(_link, id, []), do: id
  defp _id(_link, id, _collection), do: id
end
