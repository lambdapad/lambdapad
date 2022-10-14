defmodule Lambdapad.Html.Erlydtl do
  @moduledoc """
  Implementation for the HTML rendering using ErlyDTL. ErlyDTL
  in the same way EEx and other systems for the generation of
  the templates, is creating a new module with the rendering
  functions inside letting us to create the HTML files providing
  the specific data for it.

  See `Lambdapad.Html` for further information.
  """
  @behaviour Lambdapad.Html
  alias Lambdapad.Cli

  @doc false
  @impl Lambdapad.Html
  def init(type, name, html_file, workdir) when is_binary(name) do
    type = Macro.camelize(to_string(type))
    module = Module.concat([__MODULE__, type, Macro.camelize(name)])

    if Code.ensure_loaded?(module) do
      module
    else
      templates_dir = Path.join([workdir, "templates"])
      html_file_path = to_charlist(Path.join([templates_dir, html_file]))

      opts = [
        :return,
        libraries: [
          {"widget", Lambdapad.Html.Erlydtl.Widget},
          {"filters", Lambdapad.Html.Erlydtl.Filters}
        ],
        default_libraries: ~w[ widget filters ]
      ]

      case :erlydtl.compile_file(html_file_path, module, opts) do
        {:ok, _module, warnings} ->
          warnings = filter_warnings(warnings)

          if warnings != [] do
            Cli.print_level2_warn("#{inspect(warnings)}")
          end

          module

        {:error, error, []} ->
          raise """
          template #{inspect(name)} file #{inspect(html_file)} not found

          error: #{inspect(error)}
          """
      end
    end
  end

  defp filter_warnings(warnings) do
    filter_warnings(warnings, [])
  end

  defp filter_warnings([], acc), do: acc

  defp filter_warnings([{_file, [{:none, _, :no_out_dir}]} | rest], acc) do
    filter_warnings(rest, acc)
  end

  defp filter_warnings([{'', [{_n, :sys_core_fold, :useless_building}]} | rest], acc) do
    filter_warnings(rest, acc)
  end

  defp filter_warnings([warning | rest], acc) do
    filter_warnings(rest, [warning | acc])
  end
end
