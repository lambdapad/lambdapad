defmodule Lambdapad.Html.Erlydtl.Widget do
  @moduledoc """
  The widget extension is a simple way for injecting the content from the
  widgets inside of the ErlyDTL templates.

  It's defining the tag `widget` using a parameter to indicate the name.
  Given the name, it could get the information requested from the widgets
  configuration and inject that widget in the place we want. For example:

  ```
  {% widget "aside" %}
  ```
  """
  @behaviour :erlydtl_library

  @doc false
  def version, do: 1

  @doc false
  def inventory(:filters), do: []

  def inventory(:tags), do: [:widget]

  @doc """
  The widget tag provides the functionality to inject the desired widget in
  the expected place.
  """
  def widget([name], config) do
    {"widgets", widgets_lang} = List.keyfind(config, "widgets", 0)
    {"language", language} = List.keyfind(config, "language", 0)

    with {^language, widgets} <- List.keyfind(widgets_lang, language, 0),
         {^name, content} <- List.keyfind(widgets, name, 0) do
      content
    else
      nil -> raise "widget #{inspect(name)} (locale #{language}) not found!"
    end
  end
end
