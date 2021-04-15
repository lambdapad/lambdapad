defmodule Lambdapad.Generate.Sources do
  alias Lambdapad.Cli

  @table :files
  @opts [smartypants: false, gfm_tables: true, footnotes: true]

  def init() do
    {:ok, @table} = Pockets.new(@table)
    :ok
  end

  def terminate() do
    Pockets.close(@table)
  end

  def get_files(%{from: nil}, _workdir), do: nil
  def get_files(%{from: source, cache: false} = page_data, workdir) do
    data =
      Path.join(workdir, source)
      |> Path.wildcard()
      |> Enum.map(&get_file(&1, page_data[:headers], page_data[:excerpt]))

    Pockets.put(@table, source, data)
    data
  end
  def get_files(%{from: source} = page_data, workdir) do
    Pockets.get(@table, source) || get_files(Map.put(page_data, :cache, false), workdir)
  end

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
    {_status, html, messages} = Earmark.as_html(binary, @opts)
    Enum.each(messages, fn {:warning, line, message} ->
      Cli.print_level2_warn([file, ":", to_string(line), " ", message])
    end)
    html
  end

  defp get_excerpt_html(binary, file) do
    {_status, html, messages} = Earmark.as_html(binary, @opts)
    Enum.each(messages, fn {:warning, line, message} ->
      Cli.print_level2_warn([file, ":", to_string(line), " ", message])
    end)
    html
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
