defmodule Lambdapad.Blog.Base do
  @moduledoc """
  The base functions in use for the compiled module. This module
  is a try to simplify a bit more the `Lambdapad.Blog` module which
  will be generated on-the-fly.
  """
  alias Lambdapad.Blog

  @doc false
  def configs(configs) do
    for name <- configs, do: Blog.config(name)
  end

  @doc false
  def transforms(transforms) do
    for name <- transforms, into: %{} do
      {name, Blog.transform(name)}
    end
  end

  @doc false
  def checks(checks) do
    for name <- checks, into: %{} do
      {name, Blog.check(name)}
    end
  end

  @doc false
  def widgets(widgets) do
    for name <- widgets, into: %{} do
      {name, Blog.widget(name)}
    end
  end

  defp priority(:low), do: 100
  defp priority(:high), do: 0
  defp priority(num) when num in 0..100, do: num
  defp priority(nil), do: 50

  defp priority(other) do
    IO.warn(
      "Priority don't recognized: #{inspect(other)}; it should be 0..100, :low, or :high; using 50"
    )

    50
  end

  defp get_priority(%{"priority" => priority}), do: priority
  defp get_priority(%{priority: priority}), do: priority

  defp get_priority(data) when is_list(data) do
    case Enum.find(data, fn {key, _} -> key in ["priority", :priority] end) do
      {_key, priority} -> priority
      _ -> nil
    end
  end

  defp get_priority(_), do: nil

  defp maybe_order_by_priority(elements) do
    if Enum.any?(elements, fn {_, data} -> get_priority(data) != nil end) do
      Enum.sort_by(elements, fn {_key, data} -> priority(get_priority(data)) end)
    else
      elements
    end
  end

  @doc false
  def pages(pages) do
    pages
    |> Enum.map(&{&1, Blog.pages(&1)})
    |> maybe_order_by_priority()
  end

  @doc false
  def assets([]), do: %{"general" => Blog.assets("general")}

  def assets(assets) do
    assets
    |> Enum.map(&{&1, Blog.assets(&1)})
    |> maybe_order_by_priority()
  end

  @doc """
  Retrieve the configs based on the called module and the arguments received
  from the command line (as are).
  """
  def get_configs({calling_mod, _} = mod, rawargs), do: calling_mod.get_configs(mod, rawargs)

  @doc """
  Retrieve the widget blocks based on the module and providing the
  configuration from the configuration file.
  """
  def get_widgets({calling_mod, _} = mod, config), do: calling_mod.get_widgets(mod, config)

  @doc """
  Retrieve the page blocks based on the module and providing the
  configuration from the configuration file.
  """
  def get_pages({calling_mod, _} = mod, config), do: calling_mod.get_pages(mod, config)

  @doc """
  Retrieve the assets blocks based on the module and providing the
  configuration from the configuration file.
  """
  def get_assets({calling_mod, _} = mod, config), do: calling_mod.get_assets(mod, config)

  @doc """
  Retrieve the transforms blocks based on the module and providing the
  configuration from the configuration file.
  """
  def apply_transform({calling_mod, _} = mod, items), do: calling_mod.apply_transform(mod, items)

  @doc """
  Retrieve the page checks based on the module and providing the
  configuration from the configuration file.
  """
  def get_checks({calling_mod, _} = mod), do: calling_mod.get_checks(mod)

  @doc """
  Performs the compilation of the input file.
  """
  def compile(filename) do
    case Path.extname(filename) do
      "." <> extension ->
        mod = Module.concat([Lambdapad.Blog, Macro.camelize(extension)])
        Code.ensure_loaded!(mod)

        if function_exported?(mod, :compile, 1) do
          mod.compile(filename)
        else
          {:error, :module_not_found}
        end

      _ ->
        {:error, :invalid_extension}
    end
  end
end
