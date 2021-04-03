defmodule Lambdapad.Html.Widget do
  require Logger
  @behaviour :erlydtl_library

  def version, do: 1

  def inventory(:filters), do: []

  def inventory(:tags), do: [:widget]

  def widget([name], config) do
    {"widgets", widgets} = List.keyfind(config, "widgets", 0)
    {^name, content} = List.keyfind(widgets, name, 0)
    content
  end
end
