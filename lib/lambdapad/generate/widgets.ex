defmodule Lambdapad.Generate.Widgets do
  @moduledoc """
  Perform the execution of the widgets giving the data available for that. The
  widget is a fast and small snippet that we can inject in pages because it's
  stored in the configuration.

  See information in the template you are using to know how to use it.

  The main concern of this module is the generation of the module for the
  widget rendering.
  """

  alias Lambdapad.{Cli, Config, Generate, Html}
  alias Lambdapad.Generate.Sources

  @doc false
  def process(widgets, config, mod, workdir) do
    Enum.reduce(widgets, %{}, fn {name, widget_data}, acc ->
      Cli.print_level2("Widget", name)
      format = widget_data[:format]
      template_name = widget_data[:template]
      render_mod = Html.init(:widget, name, template_name, workdir, format)

      pages =
        widget_data
        |> Sources.get_files(workdir)
        |> process_transforms_on_item(mod, config, widget_data)
        |> process_transforms_on_page(mod, config, widget_data)

      plist_config =
        config
        |> process_transforms_on_config(mod, pages, widget_data)
        |> Config.to_proplist()

      vars =
        pages
        |> Config.to_proplist()
        |> get_vars(widget_data[:var_name])

      env_data = Config.to_proplist(widget_data[:env]) || []
      iodata = Html.render(vars, render_mod, plist_config ++ env_data)
      Cli.print_level2_ok()
      Map.put(acc, name, iodata)
    end)
  end

  defp get_vars(pages, :plain) do
    if Enum.all?(pages, &is_tuple/1) do
      pages
    else
      Cli.print_level2_warn("widget cannot use :plain with lists, fallback to var_name \"pages\"")
      [{"pages", pages}]
    end
  end

  defp get_vars(pages, var_name) when is_binary(var_name) do
    [{var_name, pages}]
  end

  defp process_transforms_on_item(pages, mod, config, widget_data) do
    if transforms = Generate.resolve_transforms_on_item(mod, widget_data) do
      for page <- pages do
        transforms.(page, config)
      end
    else
      pages
    end
  end

  defp process_transforms_on_page(pages, mod, config, widget_data) do
    if transforms = Generate.resolve_transforms_on_page(mod, widget_data) do
      transforms.(pages, config)
    else
      pages
    end
  end

  defp process_transforms_on_config(config, mod, pages, widget_data) do
    if transforms = Generate.resolve_transforms_on_config(mod, widget_data) do
      transforms.(config, pages)
    else
      config
    end
  end
end
