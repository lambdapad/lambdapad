defmodule Lambdapad.Cli.Command.Templates do
  @moduledoc """
  Templates command. This command for CLI is showing the list of templates.
  The templates are going to be in the root directory inside of the
  `templates` directory.
  """
  use Lambdapad.Cli.Command

  @external_resource "templates/*"
  Module.register_attribute(__MODULE__, :templates, accumulate: true)

  for "templates/" <> template <- Path.wildcard("templates/*") do
    @templates template
  end

  defp list_templates, do: @templates

  @impl Lambdapad.Cli.Command
  def command(_args) do
    IO.write("Available templates: ")

    list_templates()
    |> Enum.join(", ")
    |> IO.puts()
  end

  @impl Lambdapad.Cli.Command
  def options do
    [
      name: "templates",
      about: "List available templates"
    ]
  end
end
