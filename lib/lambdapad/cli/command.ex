defmodule Lambdapad.Cli.Command do
  @moduledoc """
  Base module for the commands. This module is which should be "in use"
  when we are creating new commands:

  ```elixir
  defmodule Lambdapad.Cli.Command.MyCommand do
    use Lambdapad.Cli.Command

    @impl Lambdapad.Cli.Command
    def options() do
      []
    end

    @impl Lambdapad.Cli.Command
    def command(params) do
      %% do your thing!
    end
  end
  ```
  """

  defmacro __using__(_opts) do
    quote do
      @behaviour Lambdapad.Cli.Command

      @doc false
      def options, do: nil

      @doc false
      def get_name do
        Module.split(__MODULE__)
        |> List.last()
        |> String.downcase()
        |> String.to_atom()
      end

      defoverridable options: 0, get_name: 0
    end
  end

  @doc """
  Command callback. The definition for the command implementation. The only
  fixed parameter you are going to receive is:

  - `infile` where it could be `lambdapad.exs` or `index.erl`.
  - `rawargs` where you get the args as they were received.

  The rest of the parameters depends on the configuration of the options.
  """
  @callback command(map()) :: :ok

  @doc """
  Retrieves the name for the subcommand.
  """
  @callback get_name() :: atom()

  @doc """
  Options callback. It defines the options which we could receive. It's
  based on the [Optimus](https://hex.pm/packages/optimus) options parser
  where we can define the `name`, `about`, `args`, `flags` and `options`.
  """
  @callback options() :: Keyword.t() | nil

  @doc """
  Retrieve all of the modules with the `Lambdapad.Cli.Command` root, which are
  intended to be the commands available for the system.
  """
  def get_modules do
    for {mod, _, _} <- :code.all_available(),
        String.starts_with?(to_string(mod), "Elixir.Lambdapad.Cli.Command."),
        do: List.to_existing_atom(mod)
  end

  @doc """
  Retrieves the configuration of the module for the CLI.
  """
  def get_options(module) do
    if options = module.options() do
      name =
        if function_exported?(module, :name, 0) do
          module.name()
        else
          Module.split(module)
          |> List.last()
          |> Macro.underscore()
          |> String.to_atom()
        end

      {name, options}
    end
  end
end
