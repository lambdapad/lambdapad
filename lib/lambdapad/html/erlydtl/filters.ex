defmodule Lambdapad.Html.Erlydtl.Filters do
  @moduledoc """
  These filters are in use for ErlyDTL and provide functions very useful
  for Lambdapad Markdown files.

  The filters provided by this module are:

  - `read_file`: read a file given the filename and put it as is into the
    template.
  - `markdown_to_html`: convert a markdown text into HTML.
  """
  @behaviour :erlydtl_library

  def version, do: 1

  @doc false
  def inventory(:filters), do: [:read_file, :markdown_to_html]

  def inventory(:tags), do: []

  defp abs_filename("/" <> _ = filename), do: filename

  defp abs_filename(relative_name) do
    Path.join([Application.get_env(:lambdapad, :workdir, ""), relative_name])
  end

  @typep filename() :: String.t()
  @typep lines_spec() :: String.t()

  @doc """
  Read a file and return the content to be injected into the HTML file
  for the template.
  """
  @spec read_file(filename()) :: String.t()
  def read_file(:undefined), do: ""

  def read_file(file) do
    file
    |> abs_filename()
    |> File.read!()
  end

  @doc """
  Read a file and return the content to be injected into the HTML file
  for the template. We could specify the lines to be retrieved from
  the file and inject into the template only those lines from the
  text file.

  As an example:

  ```
  {{ page.filename | read_file }}
  ```
  """
  @spec read_file(:undefined, lines_spec()) :: String.t()
  def read_file(:undefined, _), do: ""

  @spec read_file(String.t(), lines_spec()) :: [String.t()]
  def read_file(file, lines_spec) when is_binary(lines_spec) do
    file = abs_filename(file)

    pattern = ~r/^([0-9]+)?:(-?[0-9]+)?$/
    opts = [:binary, capture: :all_but_first]
    {first, last} = match_to_lines(Regex.run(pattern, lines_spec, opts), lines_spec)

    file
    |> abs_filename()
    |> File.stream!()
    |> Stream.with_index(1)
    |> Stream.drop_while(fn {_, i} -> i < first end)
    |> Stream.take_while(fn {_, i} -> last == :infinity or i <= last end)
    |> Enum.map(fn {line, _} -> line end)
  end

  defp match_to_lines([], _spec), do: {1, :infinity}
  defp match_to_lines([first], _spec), do: {String.to_integer(first), :infinity}
  defp match_to_lines(["", last], _spec), do: {1, String.to_integer(last)}

  defp match_to_lines([first, last], _spec),
    do: {String.to_integer(first), String.to_integer(last)}

  defp match_to_lines(nil, spec), do: throw({:lines_spec, spec})

  defp options do
    Application.get_env(:lambdapad, :html_options,
      smartypants: false,
      gfm_tables: true,
      footnotes: true,
      sub_sup: true
    )
  end

  @doc """
  This filter help us to convert Markdown text into HTML. It could be useful
  when we need to convert text from a file to HTML at the template level. For
  example:

  ```
  {{ page.content_markdown | markdown_to_html | safe }}
  ```
  """
  @spec markdown_to_html(:undefined) :: String.t()
  def markdown_to_html(:undefined), do: ""

  @spec markdown_to_html(String.t()) :: {:safe, String.t() | [String.t()]}
  def markdown_to_html(text) do
    {_status, html, _messages} = Earmark.as_html(text, options())
    {:safe, html}
  end
end
