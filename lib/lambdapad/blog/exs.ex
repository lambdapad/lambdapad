defmodule Lambdapad.Blog.Exs do
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

  @doc """
  Calls directly to the `Lambdapad.Blog.configs/0` implementation defined
  by the Elixir input file.
  """
  def get_configs({__MODULE__, mod}, _rawargs), do: mod.configs()

  @doc """
  Calls directly to the `Lambdapad.Blog.widgets/0` implementation defined
  by the Elixir input file.
  """
  def get_widgets({__MODULE__, mod}, _config), do: mod.widgets()

  @doc """
  Calls directly to the `Lambdapad.Blog.pages/0` implementation defined
  by the Elixir input file.
  """
  def get_pages({__MODULE__, mod}, _config), do: mod.pages()

  @doc """
  Calls directly to the `Lambdapad.Blog.assets/0` implementation defined
  by the Elixir input file.
  """
  def get_assets({__MODULE__, mod}, _config), do: mod.assets()

  @doc """
  Calls directly to the `Lambdapad.Blog.transform/1` implementation defined
  by the Elixir input file.
  """
  def apply_transform({__MODULE__, mod}, items), do: mod.transform(items)

  @doc """
  Calls directly to the `Lambdapad.Blog.checks/0` implementation defined
  by the Elixir input file.
  """
  def get_checks({__MODULE__, mod}), do: mod.checks()
end
