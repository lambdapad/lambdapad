defmodule Lambdapad.Cli.Exs do

  def compile(lambdapad_file) do
    [{mod, _}] = Code.compile_file(lambdapad_file)
    {:ok, {__MODULE__, mod}}
  end

  def get_configs({__MODULE__, mod}, _rawargs), do: mod.configs()

  def get_widgets({__MODULE__, mod}, _config), do: mod.widgets()

  def get_pages({__MODULE__, mod}, _config), do: mod.pages()

  def get_assets({__MODULE__, mod}, _config), do: mod.assets()

  def apply_transform({__MODULE__, mod}, items), do: mod.transform(items)
end
