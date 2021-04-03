defmodule Lambdapad.Html do
  require Logger

  def init(name, html_file, workdir, :erlydtl) when is_binary(name) do
    module = Module.concat([__MODULE__, Macro.camelize(name)])
    Logger.debug("creating module #{module} for erlydtl")
    if not function_exported?(module, :__info__, 1) do
      templates_dir = Path.join([workdir, "templates"])
      html_file_path = to_charlist(Path.join([templates_dir, html_file]))
      opts = [
        :return,
        libraries: [{"widget", Lambdapad.Html.Widget}],
        default_libraries: ["widget"]
      ]
      case :erlydtl.compile_file(html_file_path, module, opts) do
        {:ok, _module, warnings} ->
          if warnings != [], do: Logger.warn("warnings: #{inspect(warnings)}")
          Logger.info("processed #{module}")
          {:ok, module}

        {:error, error, []} ->
          {:error, error}
      end
    else
      {:ok, module}
    end
  end

  def render(vars, module, config) do
    vars = vars ++ config
    {:ok, data} = apply(module, :render, [vars, config])
    IO.iodata_to_binary(data)
  end
end
