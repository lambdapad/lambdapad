defmodule Lambdapad.Cli.CommandTest do
  use ExUnit.Case
  alias Lambdapad.Cli.Command

  defmodule Sample do
    use Lambdapad.Cli.Command

    @impl Lambdapad.Cli.Command
    def command(_params), do: :ok
  end

  test "the default options/0 is nil and get_name/0 derives the name from the module" do
    assert Sample.options() == nil
    assert Sample.get_name() == :sample
  end

  test "get_modules/0 lists every Lambdapad.Cli.Command.* implementation" do
    modules = Command.get_modules()

    assert Lambdapad.Cli.Command.Templates in modules
    assert Lambdapad.Cli.Command.Http in modules
    assert Lambdapad.Cli.Command.Clean in modules
  end

  test "get_options/1 returns {name, options} for a module with options" do
    assert {:templates, options} = Command.get_options(Lambdapad.Cli.Command.Templates)
    assert options[:name] == "templates"
  end

  test "get_options/1 returns nil for a module without options" do
    assert Command.get_options(Sample) == nil
  end
end
