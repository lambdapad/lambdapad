defmodule Lambdapad.Generate.Sources do
  @moduledoc """
  Creates a pocket (using [Pockets](https://hex.pm/packages/pockets)) in memory
  to store all of the Markdown files to be processed. The data stored for each
  file is determined by the headers inside of each file, but it's also creating
  other keys like:

  - `excerpt_raw` the excerpt in the same format it appears inside of the file.
  - `excerpt_html` the excerpt converted from Markdown to HTML.
  - `excerpt` the excerpt converted to text format.
  - `content_raw` the content of the file in the same format at it appears.
  - `content_text` the content of the file converted in plain text.
  - `content` the content of the file converted from Markdown to HTML.
  """
  alias Lambdapad.Cli

  @table :files

  @doc """
  Starts the pockets dependency to create the cache.
  """
  def init do
    {:ok, @table} = Pockets.new(@table)
    :ok
  end

  @doc """
  Stops the pockets.
  """
  def terminate do
    Pockets.close(@table)
  end

  @doc """
  Get the files content. The first time we call the function it is processing
  the files and converting the data. The next times it's retrieved from the
  pockets.

  As the first parameter it's passed the data according to the configuration.
  The second parameter is the working directory.

  It could return `nil` if there are no sources defined (based on `from`
  parameter).
  """
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

  @doc """
  Retrieve only one file. It's not using the cache, it's reading all of the
  times the file from the filesystem and processing it to return a map with
  all of the information.
  """
  def get_file(file, has_headers?, has_excerpt?)
      when is_boolean(has_headers?) and is_boolean(has_excerpt?) do
    content = File.read!(file)

    {header, post} =
      if has_headers? do
        [header, post] = String.split(content, "\n\n", parts: 2)
        {get_header(header), post}
      else
        {%{"id" => Path.rootname(Path.basename(file))}, content}
      end

    excerpt =
      if has_excerpt? do
        case String.split(post, ~r/\n<!--\s*more\s*-->\s*\n/, parts: 2) do
          [excerpt, _] -> excerpt
          [_] -> hd(String.split(post, "\n", parts: 2))
        end
      end

    header
    |> Map.put("excerpt_raw", excerpt)
    |> Map.put("excerpt_html", to_html(excerpt, file))
    |> Map.put("excerpt", to_text(excerpt, file))
    |> Map.put("content_raw", post)
    |> Map.put("content_text", to_text(post, file))
    |> Map.put("content", to_html(post, file))
  end

  defp options do
    Application.get_env(:lambdapad, :html_options,
      smartypants: false,
      gfm_tables: true,
      footnotes: true,
      sub_sup: true
    )
  end

  defp to_html(nil, _file), do: nil

  defp to_html(binary, file) do
    {_status, html, messages} = Earmark.as_html(binary, options())

    Enum.each(messages, fn {:warning, line, message} ->
      Cli.print_level2_warn([file, ":", to_string(line), " ", message])
    end)

    html
  end

  defp to_text(nil, _file), do: nil

  defp to_text(binary, file) do
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
  defp ast_to_text(bin, text) when is_binary(bin), do: [bin | text]

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
