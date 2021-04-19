defmodule Lambdapad.Generate do
  alias Lambdapad.{Cli, Config}

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

  def resolve_transforms_on_item(mod, %{transform_on_item: trans_items}) when is_list(trans_items) do
    trans_items
    |> Enum.reverse()
    |> Enum.reduce(fn posts, _config -> posts end, fn
      (trans_item, chained_fun) when is_binary(trans_item) ->
        case Cli.apply_transform(mod, trans_item) do
          %{on: :item, run: trans_function} ->
            fn posts, config ->
              trans_function.(posts, config)
              |> chained_fun.(config)
            end

          %{on: other} when other in [:page, :config, :persist] ->
            raise "transforms persist, config, page and item cannot be swapped"

          error ->
            raise "transform #{inspect(trans_item)} unknown: #{inspect(error)}"
        end

      (trans_item, chained_fun) when is_function(trans_item) ->
        fn posts, config ->
          trans_item.(posts, config)
          |> chained_fun.(config)
        end
    end)
  end
  def resolve_transforms_on_item(mod, %{transform_on_item: trans_items}) when is_binary(trans_items) do
    case Cli.apply_transform(mod, trans_items) do
      %{on: :item, run: trans_function} ->
        trans_function

      %{on: other} when other in [:page, :config, :persist] ->
        raise "transforms persist, config, page and item cannot be swapped"

      error ->
        raise "transform #{inspect(trans_items)} unknown: #{inspect(error)}"
    end
  end
  def resolve_transforms_on_item(_mod, %{transform_on_item: trans_items}) when is_function(trans_items) do
    trans_items
  end
  def resolve_transforms_on_item(_mod, %{}), do: nil

  def resolve_transforms_on_page(mod, %{transform_on_page: trans_page}) when is_list(trans_page) do
    trans_page
    |> Enum.reverse()
    |> Enum.reduce(fn posts, _config -> posts end, fn
      (trans_page, chained_fun) when is_binary(trans_page) ->
        case Cli.apply_transform(mod, trans_page) do
          %{on: :page, run: trans_function} ->
            fn posts, config ->
              trans_function.(posts, config)
              |> chained_fun.(config)
            end

          %{on: other} when other in [:item, :config, :persist] ->
            raise "transforms persist, config, page and item cannot be swapped"

          error ->
            raise "transform #{inspect(trans_page)} unknown: #{inspect(error)}"
        end

      (trans_page, chained_fun) when is_function(trans_page) ->
        fn posts, config ->
          trans_page.(posts, config)
          |> chained_fun.(config)
        end
    end)
  end
  def resolve_transforms_on_page(mod, %{transform_on_page: trans_page}) when is_binary(trans_page) do
    case Cli.apply_transform(mod, trans_page) do
      %{on: :page, run: trans_function} ->
        trans_function

      %{on: other} when other in [:item, :config, :persist] ->
        raise "transforms persist, config, page and item cannot be swapped"

      error ->
        raise "transform #{inspect(trans_page)} unknown: #{inspect(error)}"
    end
  end
  def resolve_transforms_on_page(_mod, %{transform_on_page: trans_page}) when is_function(trans_page) do
    trans_page
  end
  def resolve_transforms_on_page(_mod, %{}), do: nil

  def resolve_transforms_on_config(mod, %{transform_on_config: trans_config}) when is_list(trans_config) do
    trans_config
    |> Enum.reverse()
    |> Enum.reduce(fn config, _posts -> config end, fn
      (trans_config, chained_fun) when is_binary(trans_config) ->
        case Cli.apply_transform(mod, trans_config) do
          %{on: :config, run: trans_function} ->
            fn config, posts ->
              trans_function.(config, posts)
              |> chained_fun.(posts)
            end

          %{on: other} when other in [:item, :page, :persist] ->
            raise "transforms persist, config, page and item cannot be swapped"

          error ->
            raise "transform #{inspect(trans_config)} unknown: #{inspect(error)}"
        end

      (trans_config, chained_fun) when is_function(trans_config) ->
        fn config, posts ->
          trans_config.(config, posts)
          |> chained_fun.(posts)
        end
    end)
  end
  def resolve_transforms_on_config(mod, %{transform_on_config: trans_config}) when is_binary(trans_config) do
    case Cli.apply_transform(mod, trans_config) do
      %{on: :config, run: trans_function} ->
        trans_function

      %{on: other} when other in [:item, :page, :persist] ->
        raise "transforms persist, config, page and item cannot be swapped"

      error ->
        raise "transform #{inspect(trans_config)} unknown: #{inspect(error)}"
    end
  end
  def resolve_transforms_on_config(_mod, %{transform_on_config: trans_config}) when is_function(trans_config) do
    trans_config
  end
  def resolve_transforms_on_config(_mod, %{}), do: nil

  def resolve_transforms_to_persist(mod, %{transform_to_persist: trans_persist}) when is_list(trans_persist) do
    trans_persist
    |> Enum.reverse()
    |> Enum.reduce(fn config, _posts -> config end, fn
      (trans_persist, chained_fun) when is_binary(trans_persist) ->
        case Cli.apply_transform(mod, trans_persist) do
          %{on: :persist, run: trans_function} ->
            fn config, posts ->
              trans_function.(config, posts)
              |> chained_fun.(posts)
            end

          %{on: other} when other in [:item, :page, :config] ->
            raise "transforms persist, config, page and item cannot be swapped"

          error ->
            raise "transform #{inspect(trans_persist)} unknown: #{inspect(error)}"
        end

      (trans_persist, chained_fun) when is_function(trans_persist) ->
        fn config, posts ->
          trans_persist.(config, posts)
          |> chained_fun.(posts)
        end
    end)
  end
  def resolve_transforms_to_persist(mod, %{transform_to_persist: trans_persist}) when is_binary(trans_persist) do
    case Cli.apply_transform(mod, trans_persist) do
      %{on: :persist, run: trans_function} ->
        trans_function

      %{on: other} when other in [:item, :page, :config] ->
        raise "transforms persist, config, page and item cannot be swapped"

      error ->
        raise "transform #{inspect(trans_persist)} unknown: #{inspect(error)}"
    end
  end
  def resolve_transforms_to_persist(_mod, %{transform_to_persist: trans_persist}) when is_function(trans_persist) do
    trans_persist
  end
  def resolve_transforms_to_persist(_mod, %{}), do: nil
end
