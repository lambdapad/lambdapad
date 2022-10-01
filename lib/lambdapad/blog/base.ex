defmodule Lambdapad.Blog.Base do
  @moduledoc """
  The base functions in use for the compiled module. This module
  is a try to simplify a bit more the `Lambdapad.Blog` module which
  will be generated on-the-fly.
  """
  alias Lambdapad.Blog

  def configs(configs) do
    for name <- configs, do: Blog.config(name)
  end

  def transforms(transforms) do
    for name <- transforms, into: %{} do
      {name, Blog.transform(name)}
    end
  end

  def checks(checks) do
    for name <- checks, into: %{} do
      {name, Blog.check(name)}
    end
  end

  def widgets(widgets) do
    for name <- widgets, into: %{} do
      {name, Blog.widget(name)}
    end
  end

  defp priority(:low), do: 100
  defp priority(:high), do: 0
  defp priority(_), do: 50

  def pages(pages) do
    pages =
      for name <- pages do
        {name, Blog.pages(name)}
      end

    if Enum.any?(pages, fn {_, data} -> data["priority"] != nil end) do
      Enum.sort_by(pages, fn {_key, data} -> priority(data["priority"]) end)
    else
      pages
    end
  end

  def assets([]), do: %{"general" => Blog.assets("general")}

  def assets(assets) do
    for name <- assets, into: %{} do
      {name, Blog.assets(name)}
    end
  end
end
