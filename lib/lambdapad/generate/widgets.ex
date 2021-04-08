defmodule Lambdapad.Generate.Widgets do
  require Logger
  alias Lambdapad.{Config, Generate, Html}

  def process(widgets, config, mod, workdir) do
    Enum.reduce(widgets, %{}, fn {name, widget_data}, acc ->
      Logger.info("processing widget #{name}")
      format = widget_data[:format]
      template_name = widget_data[:template]
      render_mod = Html.init(name, template_name, workdir, format)

      pages =
        widget_data
        |> get_files(workdir)
        |> process_transforms_on_item(mod, config, widget_data)
        |> process_transforms_on_page(mod, config, widget_data)

      plist_config =
        config
        |> process_transforms_on_config(mod, pages, widget_data)
        |> Config.to_proplist()

      pages = Config.to_proplist(pages)
      vars =
        case widget_data[:var_name] do
          :plain ->
            if Enum.all?(pages, &is_tuple/1) do
              pages
            else
              Logger.warn("widget cannot use :plain with lists, fallback to var_name \"pages\"")
              [{"pages", pages}]
            end

          var_name when is_binary(var_name) ->
            [{var_name, pages}]
        end

      iodata = Html.render(vars, render_mod, plist_config)
      Map.put(acc, name, iodata)
    end)
  end

  defp get_files(%{from: source} = widget_data, workdir) do
    Path.join(workdir, source)
    |> Path.wildcard()
    |> Stream.map(&Generate.get_file(&1, widget_data[:headers], widget_data[:excerpt]))
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
