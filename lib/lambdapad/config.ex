defmodule Lambdapad.Config do
  @moduledoc """
  Handle the configuration for Lambdapad. The configuration is provided
  inside of the configuration files and it could be defined as TOML or
  Eterm at the moment.
  """
  alias Lambdapad.Cli

  @type filename() :: String.t()
  @type workdir() :: String.t()

  @doc """
  Callback for ensuring we can read data for the implementation we are doing.
  It's passing the filename, the working directory and it's returning an
  ok-tuple with the map with the data inside or an error-tuple with the
  reason as an atom.
  """
  @callback read_data(filename(), workdir()) :: {:ok, map()} | {:error, atom()}

  @doc """
  Get information about Lambdapad and when the command was launched.
  This information is useful to know the last time a page was rendered.
  """
  def lambdapad_metainfo do
    spec =
      unquote(
        Keyword.take(Lambdapad.MixProject.project(), ~w[name version description homepage_url]a)
      )

    today = Date.utc_today()
    months = ~w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]

    %{
      "lambdapad" => %{
        "name" => spec[:name],
        "vsn" => spec[:version],
        "description" => spec[:description],
        "url" => spec[:homepage_url]
      },
      "build" => %{
        "date" => to_string(today),
        "year" => today.year,
        "month" => Enum.at(months, today.month - 1),
        "day" => today.day
      }
    }
  end

  @doc """
  Retrieve the valid configurations based on the available modules.
  """
  def valid_configs do
    for {mod, _, _} <- :code.all_available(),
        String.starts_with?(to_string(mod), "Elixir.Lambdapad.Config.") do
      List.to_existing_atom(mod)
      |> Module.split()
      |> List.last()
      |> String.downcase()
      |> String.to_atom()
    end
  end

  @doc """
  Perform the initialization of the configuration based on the config blocks
  and the working directory.
  """
  def init(configs, workdir) when is_list(configs) do
    Enum.reduce(configs, {:ok, %{}}, fn config, {:ok, acc} ->
      {:ok, cfg} = init(config, workdir)
      {:ok, Map.merge(acc, cfg)}
    end)
  end

  def init(%{format: format, from: file} = config, workdir) do
    module = Module.concat([__MODULE__, Macro.camelize(to_string(format))])
    Cli.print_level2("Parsing (#{format})", file)

    case module.read_data(file, workdir) do
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

  defp process_data(config_data, %{transform: transform}, workdir)
       when is_function(transform, 1) do
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

  @doc """
  Transform data to the proplist format. It's intended that
  a map, list of elements or whatever else, could be transformed
  as a proper proplist which could be better handle by ErlyDTL.
  """
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
