defmodule Lambdapad.Blog.Erl do
  @moduledoc """
  Performs the compilation of the Erlang configuration file. The
  `index.erl` file, that's the file expected to be loaded as the
  code from Erlang, it's compiled on-the-fly and the defined
  functions are used for the configuration.
  """
  alias Lambdapad.Cli

  @compiler_opts ~w[
    return_errors
    return_warnings
    nowarn_export_all
    export_all
  ]a

  @doc """
  Performs the compilation of the Erlang code.
  """
  def compile(index_file) do
    :code.purge(:index)

    case :compile.file(String.to_charlist(index_file), @compiler_opts) do
      {:ok, mod, []} ->
        {:module, ^mod} = :code.load_file(mod)
        {:ok, {__MODULE__, mod}}

      {:ok, mod, warns} ->
        for warn <- warns do
          Cli.print_level2_warn(warn)
        end

        {:ok, {__MODULE__, mod}}

      {:error, errors, warns} ->
        IO.puts("\n---")

        for warn <- warns do
          Cli.print_level2_warn(warn)
        end

        for {filename, lines} <- errors do
          Cli.print_error("Found #{length(lines)} error(s) in #{filename}")

          for {{row, col}, error, description} <- lines do
            Cli.print_level2_error(filename, row, col, to_string(error), description)
          end
        end

        System.halt(1)
    end
  end

  @doc """
  Retrieve the configuration information based on the module. If that's
  missing, it's providing the default block information based on the
  Erlang default configuration for the config file.
  """
  def get_configs({__MODULE__, mod}, rawargs) do
    Code.ensure_compiled!(mod)

    if function_exported?(mod, :config, 1) do
      for config <- mod.config(rawargs), do: translate_config(config)
    else
      [
        %{
          format: :eterm,
          from: "lambdapad.config"
        }
      ]
    end
  end

  defp assert_config_type(kind) do
    unless kind in Lambdapad.Config.valid_configs() do
      raise """
      The kind #{kind} isn't a valid configuration type, the valid
      configuration types are:

      #{inspect(Lambdapad.Config.valid_configs())}
      """
    end
  end

  defp translate_config({key, {kind, file}}) do
    assert_config_type(kind)
    %{format: kind, from: to_string(file), var_name: to_string(key)}
  end

  defp translate_config({kind, file}) do
    assert_config_type(kind)
    %{format: :eterm, from: to_string(file)}
  end

  @doc """
  Retrieve the widget blocks if they are defined in the Erlang input file.
  """
  def get_widgets({__MODULE__, mod}, config) do
    Code.ensure_loaded!(mod)

    if function_exported?(mod, :widgets, 1) do
      for widget <- mod.widgets(config), into: %{} do
        {key, value} = translate_page_data(widget)

        {
          key,
          value
          |> Map.delete(:uri)
          |> Map.delete(:uri_type)
          |> Map.delete(:paginated)
        }
      end
    else
      %{}
    end
  end

  @doc """
  Retrieve the page blocks if they are defined. The `pages/1` function
  must to be available inside of the Erlang input module or it produces
  an error.
  """
  def get_pages({__MODULE__, mod}, config) do
    Code.ensure_loaded!(mod)

    if function_exported?(mod, :pages, 1) do
      for page <- mod.pages(config), do: translate_page_data(page)
    else
      Cli.print_error("pages it's not defined into Erlang index.")
    end
  end

  defp pages_default do
    %{
      uri_type: :dir,
      index: false,
      paginated: false,
      format: :erlydtl,
      headers: true,
      excerpt: true,
      from: nil,
      var_name: "page",
      env: %{}
    }
  end

  defp translate_page_data({uri, {:template, template, :undefined, data}}) do
    {
      to_string(uri),
      pages_default()
      |> Map.merge(data)
      |> Map.merge(%{
        index: true,
        uri: to_string(uri),
        template: to_string(template)
      })
    }
  end

  defp translate_page_data({uri, {:template, template, {var_name, from}, data}}) do
    {
      to_string(uri),
      pages_default()
      |> Map.merge(data)
      |> Map.merge(%{
        index: true,
        uri: to_string(uri),
        template: to_string(template),
        var_name: to_string(var_name),
        from:
          cond do
            is_nil(from) -> nil
            is_list(from) -> to_string(from)
            :else -> from
          end
      })
    }
  end

  defp translate_page_data({uri, {:template_map, template, :undefined, data}}) do
    {
      to_string(uri),
      pages_default()
      |> Map.merge(data)
      |> Map.merge(%{
        uri: to_string(uri),
        template: to_string(template)
      })
    }
  end

  defp translate_page_data({uri, {:template_map, template, {var_name, from}, data}}) do
    {
      to_string(uri),
      pages_default()
      |> Map.merge(data)
      |> Map.merge(%{
        var_name: to_string(var_name),
        uri: to_string(uri),
        template: to_string(template),
        from:
          cond do
            is_nil(from) -> nil
            is_list(from) -> to_string(from)
            :else -> from
          end
      })
    }
  end

  defp translate_page_data(unknown) do
    raise """
    page data unknown: #{inspect(unknown)}
    """
  end

  @doc """
  Retrieves the assets blocks from the file. If the function isn't
  defined, it's returning the default block `general`.
  """
  def get_assets({__MODULE__, mod}, config) do
    Code.ensure_loaded!(mod)

    if function_exported?(mod, :assets, 1) do
      for {name, {from, to}} <- mod.assets(config), into: %{} do
        {to_string(name), %{from: to_string(from), to: to_string(to)}}
      end
    else
      %{"general" => %{from: "assets/**", to: "site/"}}
    end
  end

  @doc """
  The transformation isn't applied for this format. It's returning
  the items as are.
  """
  def apply_transform({__MODULE__, _mod}, items), do: items

  @doc """
  There are no checks. Erlang input file isn't defining checks at
  the moment.
  """
  def get_checks({__MODULE__, _mod}), do: []
end
