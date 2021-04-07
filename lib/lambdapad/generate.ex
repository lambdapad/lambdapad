defmodule Lambdapad.Generate do
  require Logger
  alias Lambdapad.Config

  def resolve_uri(config, name, funct_or_uri, vars, index \\ nil)

  def resolve_uri(_config, _name, funct, vars, index) when is_function(funct) do
    funct.(index, vars)
  end

  def resolve_uri(config, name, uri, vars, _index) when is_binary(uri) do
    uri_mod = Module.concat([__MODULE__, URI, name])
    unless function_exported?(uri_mod, :render, 1) do
      Logger.debug("compiling #{uri_mod}")
      {:ok, _uri_mod} = :erlydtl.compile_template(uri, uri_mod)
    end
    {:ok, iodata_uri} = uri_mod.render(vars)
    Path.join([config["blog"]["url"], IO.iodata_to_binary(iodata_uri)])
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
        case mod.transform(trans_item) do
          %{on: :item, run: trans_function} ->
            fn posts, config ->
              trans_function.(posts, config)
              |> chained_fun.(config)
            end

          %{on: :page} ->
            raise "transforms page and item cannot be swapped"

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
    case mod.transform(trans_items) do
      %{on: :item, run: trans_function} -> trans_function
      %{on: :page} -> raise "transforms page and item cannot be swapped"
      error -> raise "transform #{inspect(trans_items)} unknown: #{inspect(error)}"
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
        case mod.transform(trans_page) do
          %{on: :page, run: trans_function} ->
            fn posts, config ->
              trans_function.(posts, config)
              |> chained_fun.(config)
            end

          %{on: :item} ->
            raise "transforms page and item cannot be swapped"

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
    case mod.transform(trans_page) do
      %{on: :page, run: trans_function} -> trans_function
      %{on: :item} -> raise "transforms page and item cannot be swapped"
      error -> raise "transform #{inspect(trans_page)} unknown: #{inspect(error)}"
    end
  end
  def resolve_transforms_on_page(_mod, %{transform_on_page: trans_page}) when is_function(trans_page) do
    trans_page
  end
  def resolve_transforms_on_page(_mod, %{}), do: nil

  def get_file(file, has_headers?, has_excerpt?) when is_boolean(has_headers?) and is_boolean(has_excerpt?) do
    content = File.read!(file)

    {header, post} =
      if has_headers? do
        [header, post] = String.split(content, "\n\n", parts: 2)
        {get_header(header), post}
      else
        {%{"id" => Path.rootname(Path.basename(file))}, content}
      end

    {excerpt, excerpt_html} =
      if has_excerpt? do
        excerpt =
          case String.split(post, ~r/\n<!--\s*more\s*-->\s*\n/, parts: 2) do
            [excerpt, _] -> excerpt
            [_] -> hd(String.split(post, "\n", parts: 2))
          end

        {get_excerpt_text(excerpt, file), get_excerpt_html(excerpt, file)}
      else
        {nil, nil}
      end

    header
    |> Map.put("excerpt_html", excerpt_html)
    |> Map.put("excerpt", excerpt)
    |> Map.put("content", get_post(post, file))
  end

  defp get_post(binary, file) do
    Earmark.as_html!(binary, file: file)
  end

  defp get_excerpt_html(binary, file) do
    Earmark.as_html!(binary, file: file)
  end

  defp get_excerpt_text(binary, file) do
    binary
    |> String.split("\n")
    |> EarmarkParser.as_ast(file: file)
    |> ast_to_text()
  end

  defp ast_to_text({:ok, ast, []}) do
    ast_to_text(ast, [])
    |> Enum.reverse()
    |> Enum.join()
  end

  defp ast_to_text([], text), do: text
  defp ast_to_text(bin, text) when is_binary(bin), do: [bin|text]
  defp ast_to_text({_, _, children, _opts}, text) do
    Enum.reduce(children, text, &ast_to_text/2)
  end
  defp ast_to_text(list, text) when is_list(list) do
    Enum.reduce(list, text, &ast_to_text/2)
  end

  defp get_header(binary) do
    binary
    |> String.split("\n")
    |> Enum.map(&header/1)
    |> Enum.into(%{})
  end

  defp header(line) do
    [key, value] = String.split(String.trim(line), ":", parts: 2)
    {String.trim(key), String.trim(value)}
  end
end
