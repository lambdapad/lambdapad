defmodule Lambdapad.Cli do
  require Logger

  alias Lambdapad.{Config, Html}

  defp absname("."), do: File.cwd!()
  defp absname(dir), do: Path.absname(dir)

  def main(["--version"]) do
    project = Config.lambdapad_metainfo()["lambdapad"]
    IO.puts("#{project["name"]} v#{project["vsn"]} - #{project["url"]}")
  end

  def main([]), do: main(["lambdapad.exs"])

  def main([lambdapad_file]) do
    [{mod, _}] = Code.compile_file(lambdapad_file)
    workdir = absname(Path.dirname(lambdapad_file))
    {:ok, config} = Config.init(mod.config(), workdir)

    output_dir = Path.join([workdir, config[:output_dir] || "site"])
    :ok = File.mkdir_p(output_dir)

    widgets =
      Enum.reduce(mod.widgets(), %{}, fn {name, widget_data}, acc ->
        Logger.info("processing widget #{name}")
        format = widget_data[:format] || :erlydtl
        template_name = widget_data[:template]
        {:ok, render_mod} =
          case Html.init(name, template_name, workdir, format) do
            {:error, error} ->
              raise """
              template #{inspect(name)} file #{inspect(template_name)} not found

              error: #{inspect(error)}
              """

            {:ok, render_mod} ->
              {:ok, render_mod}
          end

        source = widget_data[:from]

        pages =
          Path.join(workdir, source)
          |> Path.wildcard()
          |> Stream.map(&get_file(&1, widget_data[:headers], widget_data[:excerpt]))

        pages =
          if transforms = resolve_transforms_on_item(mod, widget_data) do
            Stream.map(pages, fn page ->
              transforms.(page, config)
            end)
          else
            pages
          end

        pages =
          if transforms = resolve_transforms_on_page(mod, widget_data) do
            Enum.to_list(pages)
            |> transforms.(config)
          else
            Enum.to_list(pages)
          end

        plist_config = Config.to_proplist(config)
        pages = Config.to_proplist(pages)
        vars =
          case widget_data[:var_name] do
            :plain -> pages
            var_name when is_binary(var_name) -> [{var_name, pages}]
          end

        iodata = Html.render(vars, render_mod, plist_config)
        Map.put(acc, name, iodata)
      end)

    config = Map.put(config, "widgets", widgets)

    Enum.map(mod.pages(), fn {name, page_data} ->
      Logger.info("processing page #{name}")
      page_data = Map.put(page_data, "name", name)
      format = page_data[:format] || :erlydtl
      template_name = page_data[:template]
      {:ok, render_mod} =
        case Html.init(name, template_name, workdir, format) do
          {:error, error} ->
            raise """
            template #{inspect(name)} file #{inspect(template_name)} not found

            error: #{inspect(error)}
            """

          {:ok, render_mod} ->
            {:ok, render_mod}
        end

      source = page_data[:from]

      pages =
        if source do
          Path.join(workdir, source)
          |> Path.wildcard()
          |> Stream.map(&get_file(&1, page_data[:headers], page_data[:excerpt]))
        end

      pages =
        if pages do
          if transforms = resolve_transforms_on_item(mod, page_data) do
            Stream.map(pages, fn page ->
              transforms.(page, config)
            end)
          else
            pages
          end
        end

      pages =
        if pages do
          if transforms = resolve_transforms_on_page(mod, page_data) do
            Enum.to_list(pages)
            |> transforms.(config)
          else
            Enum.to_list(pages)
          end
        end

      {:ok, config} =
        if pages do
          Config.transform_from_pages(mod, config, pages)
        else
          {:ok, config}
        end

      cond do
        is_nil(pages) ->
          # FIXME the configuration here should be in map format
          plist_config = Config.to_proplist(config)
          env_data = Enum.to_list(page_data[:env])
          env = plist_config ++ env_data
          url = resolve_uri(config, name, page_data[:uri], env)
          file = build_file_abspath(output_dir, url, page_data[:uri_type])
          Logger.info("generating #{file}")
          # FIXME the configuration here should be in map format
          iodata = Html.render(env_data, render_mod, plist_config)
          File.write!(file, iodata)

        page_data[:index] and page_data[:paginated] == false ->
          # FIXME the configuration here should be in map format
          plist_config = Config.to_proplist(config)
          vars = process_vars(page_data, pages)
          env_data = Enum.to_list(page_data[:env])
          url = resolve_uri(config, name, page_data[:uri], vars ++ env_data)
          file = build_file_abspath(output_dir, url, page_data[:uri_type])
          Logger.info("generating #{file}")
          iodata = Html.render(vars ++ env_data, render_mod, plist_config)
          File.write!(file, iodata)

        page_data[:index] ->
          items_per_page =
            case page_data[:paginated] do
              pg when is_function(pg) -> pg.(pages, config)
              pg when is_integer(pg) -> pg
            end

          page_items = Enum.chunk_every(pages, items_per_page)
          total_pages = length(page_items)
          pager_data =
            for {posts, index} <- Enum.with_index(page_items, 1), into: %{} do
              vars = process_vars(page_data, posts, index)
              url = resolve_uri(config, name, page_data[:uri], vars, index)
              {index, %{
                posts: posts,
                vars: vars,
                url: url
              }}
            end
          Enum.each(1..total_pages, fn index ->
            pager =
              case index do
                ^total_pages when index == 1 ->
                  [{"pager", []}]

                ^total_pages ->
                  [{"pager", [{"prev_url", pager_data[index - 1][:url]}]}]

                1 ->
                  [{"pager", [{"next_url", pager_data[index + 1][:url]}]}]

                _ ->
                  [{"pager", [
                    {"next_url", pager_data[index + 1][:url]},
                    {"prev_url", pager_data[index - 1][:url]}
                  ]}]
              end

            vars = pager_data[index][:vars]
            env_data = Enum.to_list(page_data[:env])
            url = pager_data[index][:url]
            file = build_file_abspath(output_dir, url, page_data[:uri_type])
            Logger.info("generating #{file}")
            plist_config = Config.to_proplist(config)
            iodata = Html.render(vars ++ pager ++ env_data, render_mod, plist_config)
            File.write!(file, iodata)
          end)

        :else ->
          Enum.each(pages, fn
            {index, data} ->
              vars = process_vars(page_data, data, index)
              env_data = Enum.to_list(page_data[:env])
              url = resolve_uri(config, name, page_data[:uri], vars ++ env_data, index)
              file = build_file_abspath(output_dir, url, page_data[:uri_type])
              Logger.info("generating #{file}")
              plist_config = Config.to_proplist(config)
              iodata = Html.render(vars ++ env_data, render_mod, plist_config)
              File.write!(file, iodata)

            data when is_map(data) ->
              vars = process_vars(page_data, data)
              env_data = Enum.to_list(page_data[:env])
              url = resolve_uri(config, name, page_data[:uri], vars ++ env_data)
              file = build_file_abspath(output_dir, url, page_data[:uri_type])
              Logger.info("generating #{file}")
              plist_config = Config.to_proplist(config)
              iodata = Html.render(vars ++ env_data, render_mod, plist_config)
              File.write!(file, iodata)
          end)
      end
    end)

    Enum.each(mod.assets(), fn {name, data} ->
      Logger.debug("copying data based on #{inspect(name)} => #{inspect(data)}")
      src_path = Path.join([workdir, data[:from]])
      Logger.debug("src_path => #{src_path}")
      base_src_path =
        src_path
        |> Path.split()
        |> Enum.take_while(& not String.contains?(&1, ["*", "?", "[", "]", "{", "}"]))
        |> Path.join()

      Logger.debug("base_src_path => #{base_src_path}")
      dst_path = Path.join([workdir, data[:to]])
      Logger.debug("dst_path => #{dst_path}")
      Enum.each(Path.wildcard(src_path), fn file ->
        dst_file = String.replace_prefix(file, base_src_path, dst_path)
        Logger.info("copying #{file} to #{dst_file}")
        File.mkdir_p(Path.dirname(dst_file))
        File.cp(file, dst_file)
      end)
      Logger.debug("base_src_path => #{base_src_path}")
      Logger.debug("dst_path => #{dst_path}")
    end)

    IO.puts("Ready!")
    :ok
  end

  defp resolve_uri(config, name, funct_or_uri, vars, index \\ nil)

  defp resolve_uri(_config, _name, funct, vars, index) when is_function(funct) do
    funct.(index, vars)
  end

  defp resolve_uri(config, name, uri, vars, _index) when is_binary(uri) do
    uri_mod = Module.concat([__MODULE__, URI, name])
    unless function_exported?(uri_mod, :render, 1) do
      Logger.debug("compiling #{uri_mod}")
      {:ok, _uri_mod} = :erlydtl.compile_template(uri, uri_mod)
    end
    {:ok, iodata_uri} = uri_mod.render(vars)
    Path.join([config["blog"]["url"], IO.iodata_to_binary(iodata_uri)])
  end

  defp process_vars(page_data, data, index \\ nil)

  defp process_vars(page_data, data, nil) do
    case page_data[:var_name] do
      :plain ->
        Config.to_proplist(data)

      var_name when is_binary(var_name) ->
        [{var_name, Config.to_proplist(data)}]
    end
  end

  defp process_vars(page_data, data, index) do
    case page_data[:var_name] do
      :plain ->
        [{"index", index} | Config.to_proplist(data)]

      var_name when is_binary(var_name) ->
        [{"index", index}, {var_name, Config.to_proplist(data)}]
    end
  end

  defp build_file_abspath(output_dir, url, :dir) do
    url_data = URI.parse(url)
    abs_path = Path.absname(Path.join([output_dir, url_data.path || "/"]))
    :ok = File.mkdir_p!(abs_path)
    Path.join([abs_path, "index.html"])
  end

  defp build_file_abspath(output_dir, url, :file) do
    url_data = URI.parse(url)
    abs_path = Path.absname(Path.join([output_dir, url_data.path]))
    dir_path = Path.dirname(abs_path)
    :ok = File.mkdir_p!(dir_path)
    abs_path
  end

  defp resolve_transforms_on_item(mod, %{transform_on_item: trans_items}) when is_list(trans_items) do
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
  defp resolve_transforms_on_item(mod, %{transform_on_item: trans_items}) when is_binary(trans_items) do
    case mod.transform(trans_items) do
      %{on: :item, run: trans_function} -> trans_function
      %{on: :page} -> raise "transforms page and item cannot be swapped"
      error -> raise "transform #{inspect(trans_items)} unknown: #{inspect(error)}"
    end
  end
  defp resolve_transforms_on_item(_mod, %{transform_on_item: trans_items}) when is_function(trans_items) do
    trans_items
  end
  defp resolve_transforms_on_item(_mod, %{}), do: nil

  defp resolve_transforms_on_page(mod, %{transform_on_page: trans_page}) when is_list(trans_page) do
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
  defp resolve_transforms_on_page(mod, %{transform_on_page: trans_page}) when is_binary(trans_page) do
    case mod.transform(trans_page) do
      %{on: :page, run: trans_function} -> trans_function
      %{on: :item} -> raise "transforms page and item cannot be swapped"
      error -> raise "transform #{inspect(trans_page)} unknown: #{inspect(error)}"
    end
  end
  defp resolve_transforms_on_page(_mod, %{transform_on_page: trans_page}) when is_function(trans_page) do
    trans_page
  end
  defp resolve_transforms_on_page(_mod, %{}), do: nil

  defp get_file(file, has_headers?, has_excerpt?) when is_boolean(has_headers?) and is_boolean(has_excerpt?) do
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
