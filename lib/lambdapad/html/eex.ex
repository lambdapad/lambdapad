defmodule Lambdapad.Html.Eex do
  @moduledoc """
  Implementation of the `Lambdapad.Html` behaviour for EEx templates.
  """
  @behaviour Lambdapad.Html
  alias Lambdapad.Html.Eex, as: HtmlEex
  alias Phoenix.HTML.Engine, as: HtmlEngine

  @doc false
  @impl Lambdapad.Html
  def init(type, name, html_file, workdir) when is_binary(name) do
    type = Macro.camelize(to_string(type))
    module = Module.concat([__MODULE__, type, Macro.camelize(name)])

    if Code.ensure_loaded?(module) do
      module
    else
      load_module(module, html_file, workdir)
    end
  end

  defp load_module(module, html_file, workdir) do
    templates_dir = Path.join([workdir, "templates"])
    html_file = Path.join([templates_dir, html_file])
    html_quoted = EEx.compile_file(html_file, file: html_file, engine: HtmlEngine)

    quoted =
      quote file: html_file do
        defmodule unquote(module) do
          use Gettext, backend: Lambdapad.Blog.Gettext
          alias Lambdapad.Html.Eex, as: HtmlEex
          alias Phoenix.HTML.Engine, as: HtmlEngine
          @external_resource unquote(html_file)
          @working_dir Path.dirname(unquote(html_file))
          @current_file Path.basename(unquote(html_file), ".eex")

          @doc false
          def render(var!(assigns)) do
            _ = var!(assigns)
            {:ok, HtmlEngine.encode_to_iodata!(unquote(html_quoted))}
          end

          defp widget(name, assigns) do
            language = to_string(assigns[:language])

            with {^language, widgets} <- List.keyfind(assigns[:widgets], language, 0),
                 {^name, content} <- List.keyfind(widgets, name, 0) do
              raw(content)
            else
              nil ->
                raise """
                Cannot find #{name} (locale #{language}) in #{HtmlEex.get_names(assigns[:widgets])}
                """
            end
          end

          defp raw(data), do: {:safe, data}

          def render(@current_file, assigns), do: render(assigns)

          def render(filename, assigns),
            do: HtmlEex.render(filename, __MODULE__, @working_dir, assigns)
        end
      end

    {{:module, ^module, _, _}, _bindings} = Code.eval_quoted(quoted)
    module
  end

  @doc false
  def get_names(widgets) do
    Enum.map_join(widgets, ", ", fn {name, _value} -> name end)
  end

  @doc false
  def render(file, _module, working_dir, assigns) when is_binary(file) and is_list(assigns) do
    filename = Path.join([working_dir, file <> ".eex"])
    quoted = EEx.compile_file(filename, file: filename, engine: Phoenix.HTML.Engine)
    env = [file: filename, line: 1]

    quoted =
      quote do
        use Gettext, backend: Lambdapad.Blog.Gettext
        unquote(quoted)
      end

    {result, _bindings} = Code.eval_quoted(quoted, [assigns: assigns], env)
    result
  end

  def render(vars, module, _working_dir, config) when is_list(vars) and is_list(config) do
    case Enum.split_with(vars, fn {key, _} -> key == "widgets" end) do
      {[{_, widgets}], vars} ->
        module.render(to_keyword(vars) ++ config ++ [widgets: widgets])

      {[], vars} ->
        module.render(to_keyword(vars) ++ config)
    end
  end

  defp to_atom(atom) when is_atom(atom), do: atom
  defp to_atom(string) when is_binary(string), do: String.to_atom(string)
  defp to_atom(other), do: raise("key #{other} is invalid, it must be a string or atom")

  defp to_keyword(map) when is_map(map) do
    Enum.group_by(map, fn {key, _value} -> to_atom(key) end, &to_keyword/1)
  end

  defp to_keyword(map) when is_list(map) do
    Enum.map(map, fn
      {k, v} -> {to_atom(k), to_keyword(v)}
      list when is_list(list) -> to_keyword(list)
      map when is_map(map) -> to_keyword(map)
      property -> property
    end)
  end

  defp to_keyword(any), do: any
end
