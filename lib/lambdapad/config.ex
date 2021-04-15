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

  def init(configs, workdir) when is_list(configs) do
    Enum.reduce(configs, {:ok, %{}}, fn(config, {:ok, acc}) ->
      {:ok, cfg} = init(config, workdir)
      {:ok, Map.merge(acc, cfg)}
    end)
  end

  def init(%{format: "toml", from: file} = config, workdir) do
    Cli.print_level2("Parsing (TOML)", file)
    case Toml.decode_file(Path.join([workdir, file])) do
      {:ok, config_data} ->
        config_data = process_data(config_data, config, workdir)
        Cli.print_level2_ok()
        if var_name = config[:var_name] do
          {:ok, %{var_name => config_data}}
        else
          {:ok, config_data}
        end

      {:error, error} ->
        Cli.print_error("reading #{file}: #{inspect(error)}")
        System.halt(1)
    end
  end

  def init(%{format: "eterm", from: file} = config, workdir) do
    Cli.print_level2("Parsing (Erlang)", file)
    case :file.script(Path.join([workdir, file])) do
      {:ok, config_data} when is_map(config_data) ->
        config_data = process_data(config_data, config, workdir)
        Cli.print_level2_ok()
        if var_name = config[:var_name] do
          {:ok, %{var_name => config_data}}
        else
          {:ok, config_data}
        end

      {:ok, config_data} ->
        Cli.print_error("config data MUST be a map. Getting: #{inspect(config_data)}")
        System.halt(1)

      {:error, error} ->
        Cli.print_error("reading #{file}: #{inspect(error)}")
        System.halt(1)
    end
  end

  defp process_data(config_data, %{transform: transform}, workdir) when is_function(transform, 1) do
    config_data
    |> Map.put("workdir", workdir)
    |> transform.()
    |> string_keys()
    |> Map.merge(lambdapad_metainfo())
  end

  defp process_data(config_data, _config, workdir) do
    config_data
    |> Map.put("workdir", workdir)
    |> string_keys()
    |> Map.merge(lambdapad_metainfo())
  end

  defp string_keys(map) when is_map(map) do
    for {key, value} <- map, into: %{}, do: {to_string(key), string_keys(value)}
  end
  defp string_keys(other), do: other

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
