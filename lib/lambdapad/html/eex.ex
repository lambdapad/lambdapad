defmodule Lambdapad.Html.Eex do
  @behaviour Lambdapad.Html

  @doc false
  @impl Lambdapad.Html
  def init(type, name, html_file, workdir) when is_binary(name) do
    type = Macro.camelize(to_string(type))
    module = Module.concat([__MODULE__, type, Macro.camelize(name)])

    if Code.ensure_loaded?(module) do
      module
    else
      templates_dir = Path.join([workdir, "templates"])
      html_file = Path.join([templates_dir, html_file])

      html_quoted = EEx.compile_file(html_file, file: html_file, engine: Phoenix.HTML.Engine)
      quoted = quote file: html_file do
        defmodule unquote(module) do
          import Lambdapad.Blog.Gettext
          @external_resource unquote(html_file)
          @working_dir Path.dirname(unquote(html_file))
          @current_file Path.basename(unquote(html_file), ".eex")

          defp render(var!(assigns)) do
            _ = var!(assigns)
            {:ok, Phoenix.HTML.Engine.encode_to_iodata!(unquote(html_quoted))}
          end

          defp to_atom(atom) when is_atom(atom), do: atom
          defp to_atom(string) when is_binary(string), do: String.to_atom(string)
          defp to_atom(other), do: raise "key #{other} is invalid, it must be a string or atom"

          defp to_keyword(map) when is_map(map) do
            for {key, value} <- map do
              {to_atom(key), to_keyword(map)}
            end
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

          defp widget(name, assigns) do
            case Enum.find(assigns[:widgets], fn {key, _value} -> key == name end) do
              {^name, value} ->
                raw(value)

              _ ->
                raise """
                Cannot find #{inspect(name)} in #{inspect(Enum.map(assigns[:widgets], &elem(&1, 0)))}
                """
            end
          end

          defp raw(data), do: {:safe, data}

          def render(@current_file, assigns) do
            render(assigns)
          end

          def render(file, assigns) when is_binary(file) and is_list(assigns) do
            filename = Path.join([@working_dir, file <> ".eex"])
            quoted = EEx.compile_file(filename, file: filename, engine: Phoenix.HTML.Engine)
            {result, _bindings} = Code.eval_quoted(quoted, assigns: assigns)
            result
          end

          def render(vars, config) when is_list(vars) and is_list(config) do
            case Enum.split_with(vars, fn {key, _} -> key == "widgets" end) do
              {[{_, widgets}], vars} ->
                render(to_keyword(vars) ++ config ++ [widgets: widgets])
              {[], vars} ->
                render(to_keyword(vars) ++ config)
            end
          end
        end
      end
      {{:module, ^module, _, _}, _bindings} = Code.eval_quoted(quoted)
      module
    end
  end
end
