defmodule Lambdapad.Cli.Exs do
  @moduledoc """
  Performs the compilation for the Elixir configuration code. Mainly,
  it's reading the `lambdapad.exs` file and compiling the module as
  `Lambdapad.Blog` to process the functions as the data provided
  inside of the module.
  """

  @doc """
  Performs the compilation giving the name of the file. By default the
  filename will be `lambdapad.exs`.
  """
  def compile(lambdapad_file) do
    Code.compiler_options(ignore_module_conflict: true)
    [{mod, _}] = Code.compile_file(lambdapad_file)
    {:ok, {__MODULE__, mod}}
  end

  def get_configs({__MODULE__, mod}, _rawargs), do: mod.configs()

  def get_widgets({__MODULE__, mod}, _config), do: mod.widgets()

  def get_pages({__MODULE__, mod}, _config), do: mod.pages()

  def get_assets({__MODULE__, mod}, _config), do: mod.assets()

  def apply_transform({__MODULE__, mod}, items), do: mod.transform(items)

  def get_checks({__MODULE__, mod}), do: mod.checks()
end
