defmodule Lambdapad.Config do
  alias Lambdapad.Cli

  def lambdapad_metainfo() do
    spec = unquote(Lambdapad.MixProject.project())
    %{
      "lambdapad" => %{
        "name" => spec[:name],
        "vsn" => spec[:version],
        "description" => spec[:description],
        "url" => spec[:homepage_url]
      }
    }
  end

  def init(%{format: "toml", from: file} = config, workdir) do
    Cli.print_level2("Parsing", file)
    case Toml.decode_file(Path.join([workdir, file])) do
      {:ok, config_data} ->
        config_data = Map.put(config_data, "workdir", workdir)
        transform = config[:transform]
        config_data =
          if is_function(transform, 1) do
            transform.(config_data)
          else
            config_data
          end
          |> Map.merge(lambdapad_metainfo())

        Cli.print_level2_ok()
        {:ok, config_data}

      error ->
        Cli.print_error("#{inspect(error)}")
        System.halt(1)
    end
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
