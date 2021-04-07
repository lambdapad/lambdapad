defmodule Lambdapad.Cli do
  require Logger

  alias Lambdapad.{Config, Generate}

  defp absname("."), do: File.cwd!()
  defp absname(dir), do: Path.absname(dir)

  def main(["--version"]) do
    project = Config.lambdapad_metainfo()["lambdapad"]
    IO.puts("#{project["name"]} v#{project["vsn"]} - #{project["url"]}")
  end

  def main([]), do: main(["lambdapad.exs"])

  def main([lambdapad_file]) do
    [{mod, _}] = Code.compile_file(lambdapad_file)
    workdir = absname(Path.dirname(lambdapad_file))
    {:ok, config} = Config.init(mod.config(), workdir)

    output_dir = Path.join([workdir, config[:output_dir] || "site"])
    :ok = File.mkdir_p(output_dir)

    widgets = Generate.Widgets.process(mod.widgets(), config, mod, workdir)
    config = Map.put(config, "widgets", widgets)

    Generate.Pages.process(mod.pages(), config, mod, workdir, output_dir)
    Generate.Assets.process(mod.assets(), workdir)

    IO.puts("Ready!")
    :ok
  end
end
