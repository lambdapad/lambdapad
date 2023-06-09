defmodule Lambdapad.Generate do
  @moduledoc """
  General generation of the pages. This module contains generic functions and
  common functionality to process the pages, widgets, assets, and
  configuration for the generation of the whole website.
  """
  alias Lambdapad.{Blog, Config}

  @doc """
  Performs the render for the URI. In the configuration for the pages
  we can use or a function or a render based on ErlyDTL, this render
  is generating a module. If the module was generated in a previous
  page generation it's only used with the new data, otherwise it's
  generated and used.
  """
  def resolve_uri(config, name, funct_or_uri, vars, index \\ nil)

  def resolve_uri(_config, _name, funct, vars, index) when is_function(funct) do
    funct.(index, vars)
  end

  def resolve_uri(config, name, uri, vars, _index) when is_binary(uri) do
    uri_mod = Module.concat([__MODULE__, URI, name])

    unless function_exported?(uri_mod, :render, 1) do
      {:ok, _uri_mod} = :erlydtl.compile_template(uri, uri_mod)
    end

    {:ok, iodata_uri} = uri_mod.render(vars)
    Path.join([config["blog"]["url"] || "", IO.iodata_to_binary(iodata_uri)])
  end

  @doc """
  Generate the information needed for the website.
  """
  def process_vars(page_data, data, index \\ nil)

  def process_vars(page_data, data, nil) do
    case page_data[:var_name] do
      :plain ->
        Config.to_proplist(data)

      var_name when is_binary(var_name) ->
        [{var_name, Config.to_proplist(data)}]
    end
  end

  def process_vars(page_data, data, index) do
    case page_data[:var_name] do
      :plain ->
        [{"index", index} | Config.to_proplist(data)]

      var_name when is_binary(var_name) ->
        [{"index", index}, {var_name, Config.to_proplist(data)}]
    end
  end

  @doc """
  Create the directory base for creating the file we need to create and we
  provide the path as the return where the file must be created.
  """
  def build_file_abspath(output_dir, url, :dir) do
    url_data = URI.parse(url)
    abs_path = Path.absname(Path.join([output_dir, url_data.path || "/"]))
    :ok = File.mkdir_p!(abs_path)
    Path.join([abs_path, "index.html"])
  end

  def build_file_abspath(output_dir, url, :file) do
    url_data = URI.parse(url)
    abs_path = Path.absname(Path.join([output_dir, url_data.path]))
    dir_path = Path.dirname(abs_path)
    :ok = File.mkdir_p!(dir_path)
    abs_path
  end

  @doc """
  Creates the chain of function calling based on the list of
  transforms to be run. This time is for `transform_on_item`
  configuration.
  """
  def resolve_transforms_on_item(mod, %{transform_on_item: trans_items})
      when is_list(trans_items) do
    trans_items
    |> Enum.reverse()
    |> Enum.reduce(fn posts, _config -> posts end, fn
      trans_item, chained_fun when is_binary(trans_item) ->
        chain_function(:item, mod, trans_item, chained_fun)

      trans_item, chained_fun when is_function(trans_item) ->
        get_chain_fn(trans_item, chained_fun)
    end)
  end

  def resolve_transforms_on_item(mod, %{transform_on_item: trans_items})
      when is_binary(trans_items) do
    chain_function(:item, mod, trans_items, nil)
  end

  def resolve_transforms_on_item(_mod, %{transform_on_item: trans_items})
      when is_function(trans_items) do
    trans_items
  end

  def resolve_transforms_on_item(_mod, %{}), do: nil

  @doc """
  Creates the chain of function calling based on the list of
  transforms to be run. This time is for `transform_on_page`
  configuration.
  """
  def resolve_transforms_on_page(mod, %{transform_on_page: trans_page})
      when is_list(trans_page) do
    trans_page
    |> Enum.reverse()
    |> Enum.reduce(fn posts, _config -> posts end, fn
      trans_page, chained_fun when is_binary(trans_page) ->
        chain_function(:page, mod, trans_page, chained_fun)

      trans_page, chained_fun when is_function(trans_page) ->
        get_chain_fn(trans_page, chained_fun)
    end)
  end

  def resolve_transforms_on_page(mod, %{transform_on_page: trans_page})
      when is_binary(trans_page) do
    chain_function(:page, mod, trans_page, nil)
  end

  def resolve_transforms_on_page(_mod, %{transform_on_page: trans_page})
      when is_function(trans_page) do
    trans_page
  end

  def resolve_transforms_on_page(_mod, %{}), do: nil

  @doc """
  Creates the chain of function calling based on the list of
  transforms to be run. This time is for `transform_on_config`
  configuration.
  """
  def resolve_transforms_on_config(mod, %{transform_on_config: trans_config})
      when is_list(trans_config) do
    trans_config
    |> Enum.reverse()
    |> Enum.reduce(fn config, _posts -> config end, fn
      trans_config, chained_fun when is_binary(trans_config) ->
        chain_function(:config, mod, trans_config, chained_fun)

      trans_config, chained_fun when is_function(trans_config) ->
        get_config_chain_fn(trans_config, chained_fun)
    end)
  end

  def resolve_transforms_on_config(mod, %{transform_on_config: trans_config})
      when is_binary(trans_config) do
    chain_function(:config, mod, trans_config, nil)
  end

  def resolve_transforms_on_config(_mod, %{transform_on_config: trans_config})
      when is_function(trans_config) do
    trans_config
  end

  def resolve_transforms_on_config(_mod, %{}), do: nil

  @doc """
  Creates the chain of function calling based on the list of
  transforms to be run. This time is for `transform_on_persist`
  configuration.
  """
  def resolve_transforms_to_persist(mod, %{transform_to_persist: trans_persist})
      when is_list(trans_persist) do
    trans_persist
    |> Enum.reverse()
    |> Enum.reduce(fn config, _posts -> config end, fn
      trans_persist, chained_fun when is_binary(trans_persist) ->
        chain_function(:persist, mod, trans_persist, chained_fun)

      trans_persist, chained_fun when is_function(trans_persist) ->
        get_config_chain_fn(trans_persist, chained_fun)
    end)
  end

  def resolve_transforms_to_persist(mod, %{transform_to_persist: trans_persist})
      when is_binary(trans_persist) do
    chain_function(:persist, mod, trans_persist, nil)
  end

  def resolve_transforms_to_persist(_mod, %{transform_to_persist: trans_persist})
      when is_function(trans_persist) do
    trans_persist
  end

  def resolve_transforms_to_persist(_mod, %{}), do: nil

  defp get_chain_fn(chain_fn, chained_fn) do
    fn posts, config ->
      chain_fn.(posts, config)
      |> chained_fn.(config)
    end
  end

  defp get_config_chain_fn(chain_fn, chained_fn) do
    fn config, posts ->
      chain_fn.(config, posts)
      |> chained_fn.(posts)
    end
  end

  @types ~w[ item page config persist ]a

  def chain_function(type, mod, trans_fn, chained_fn) do
    case Blog.Base.apply_transform(mod, trans_fn) do
      %{on: ^type, run: trans_function} when type in [:config, :persist] ->
        if chained_fn do
          get_config_chain_fn(trans_function, chained_fn)
        else
          trans_function
        end

      %{on: ^type, run: trans_function} when type in [:item, :page] ->
        if chained_fn do
          get_chain_fn(trans_function, chained_fn)
        else
          trans_function
        end

      %{on: other} = debug when other != type and other in @types ->
        raise """
        transforms persist, config, page and item cannot be swapped

        data: #{inspect(debug)}
        """

      error ->
        raise "transform #{inspect(trans_fn)} unknown: #{inspect(error)}"
    end
  end
end
