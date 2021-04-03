defmodule Lambdapad.Config do
  require Logger

  quote do
    @project_data unquote(Lambdapad.MixProject.project())
  end

  def lambdapad_metainfo() do
    spec = unquote(Lambdapad.MixProject.project())
    %{
      "lambdapad" => %{
        "name" => spec[:name],
        "vsn" => spec[:version],
        "url" => spec[:homepage_url]
      }
    }
  end

  def init(%{format: "toml", from: file} = config, workdir) do
    case Toml.decode_file(Path.join([workdir, file])) do
      {:ok, config_data} ->
        config_data = Map.put(config_data, "workdir", workdir)
        config_data =
          if transform = config[:transform] do
            transform.(config_data)
          else
            config_data
          end
          |> Map.merge(lambdapad_metainfo())

        {:ok, config_data}

      error ->
        Logger.error("configuration file #{file} error: #{inspect(error)}")
        :init.stop(1)
    end
  end

  def transform_from_pages(mod, config, pages) do
    transform = resolve_transform_from_pages(mod, mod.config())
    {:ok, transform.(config, pages)}
  end

  defp resolve_transform_from_pages(mod, %{transform_from_pages: transform}) when is_list(transform) do
    transform
    |> Enum.reverse()
    |> Enum.reduce(fn pages, _config -> pages end, fn
      (trans_item, chained_fun) when is_binary(trans_item) ->
        case mod.transform(trans_item) do
          %{on: :config, run: trans_function} ->
            fn config, pages ->
              trans_function.(config, pages)
              |> chained_fun.(pages)
            end

          %{on: _} ->
            raise "transforms config, page and item cannot be swapped"

          error ->
            raise "transform #{inspect(trans_item)} unknown: #{inspect(error)}"
        end

      (trans_item, chained_fun) when is_function(trans_item) ->
        fn config, pages ->
          trans_item.(config, pages)
          |> chained_fun.(pages)
        end
    end)
  end
  defp resolve_transform_from_pages(mod, %{transform_from_pages: transform}) when is_binary(transform) do
    case mod.transform(transform) do
      %{on: :item, run: trans_function} -> trans_function
      %{on: :page} -> raise "transforms page and item cannot be swapped"
      error -> raise "transform #{inspect(transform)} unknown: #{inspect(error)}"
    end
  end
  defp resolve_transform_from_pages(_mod, %{transform_from_pages: transform}) when is_function(transform) do
    transform
  end
  defp resolve_transform_from_pages(_mod, %{}) do
    fn config, _pages -> config end
  end

  def to_proplist(%Date{day: day, month: month, year: year}) do
    [
      {"day", String.pad_leading(to_string(day), 2, "0")},
      {"month", String.pad_leading(to_string(month), 2, "0")},
      {"year", to_string(year)}
    ]
  end

  def to_proplist(map) when is_map(map) do
    to_proplist(Enum.to_list(map))
  end

  def to_proplist(map) when is_list(map) do
    Enum.map(map, fn
      {k, v} -> {k, to_proplist(v)}
      list when is_list(list) -> to_proplist(list)
      map when is_map(map) -> to_proplist(map)
      property -> property
    end)
  end

  def to_proplist(any), do: any
end
