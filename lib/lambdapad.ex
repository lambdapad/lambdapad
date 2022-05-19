defmodule Lambdapad do
  @moduledoc """
  Documentation for `Lambdapad`.
  """
  defmacro blog(do: block) do
    quote do
      defmodule Lambdapad.Blog do
        use Lambdapad

        @content nil
        Module.register_attribute(Lambdapad.Blog, :configs, accumulate: true)
        Module.register_attribute(Lambdapad.Blog, :source, accumulate: true)
        Module.register_attribute(Lambdapad.Blog, :transforms, accumulate: true)
        Module.register_attribute(Lambdapad.Blog, :checks, accumulate: true)
        Module.register_attribute(Lambdapad.Blog, :widgets, accumulate: true)
        Module.register_attribute(Lambdapad.Blog, :pages, accumulate: true)
        Module.register_attribute(Lambdapad.Blog, :assets, accumulate: true)
        unquote(block)

        def sources(), do: @source

        def configs() do
          for name <- @configs, do: __MODULE__.config(name)
        end

        def transforms() do
          for name <- @transforms, into: %{} do
            {name, transform(name)}
          end
        end

        def checks() do
          for name <- @checks, into: %{} do
            {name, check(name)}
          end
        end

        def widgets() do
          for name <- @widgets, into: %{} do
            {name, widget(name)}
          end
        end

        defp priority(:low), do: 100
        defp priority(:high), do: 0
        defp priority(_), do: 50

        def pages() do
          pages =
            for name <- @pages do
              {name, pages(name)}
            end

          if Enum.any?(pages, fn {_, data} -> not is_nil(data["priority"]) end) do
            Enum.sort_by(pages, fn {key, data} -> priority(data["priority"]) end)
          else
            pages
          end
        end

        def assets() do
          assets = if @assets == [], do: ["general"], else: @assets
          for name <- assets, into: %{} do
            {name, __MODULE__.assets(name)}
          end
        end
      end
    end
  end

  defmacro __using__(_opts) do
    quote do
      def config("default") do
        %{
          format: :toml,
          from: "config.toml",
          transform_from_pages: nil
        }
      end

      def assets("general") do
        %{
          from: "assets/**",
          to: "site/"
        }
      end
      def assets(_), do: nil

      def sources(), do: %{}

      def source(key) do
        sources()[key]
      end

      def transform(_), do: nil

      def check(_), do: nil

      def widget(_), do: nil

      def pages(_), do: nil

      defp translate_from(%{from: name} = data) when is_atom(name) do
        Map.put(data, :from, __MODULE__.source(name)) || raise "source #{name} undefined"
      end

      defp translate_from(%{} = data), do: data

      defp pages_default() do
        %{
          uri_type: :dir,
          index: false,
          paginated: false,
          format: :erlydtl,
          headers: true,
          excerpt: true,
          from: nil,
          var_name: "page",
          env: %{}
        }
      end

      defp widgets_default() do
        %{
          format: :erlydtl,
          headers: true,
          excerpt: true,
          var_name: :plain
        }
      end

      defp config_default() do
        %{
          format: :toml,
          from: "config.toml",
          transform_from_pages: nil
        }
      end

      defoverridable [
        config: 1,
        assets: 1,
        sources: 0,
        transform: 1,
        check: 1,
        widget: 1,
        pages: 1
      ]
    end
  end

  defmacro config(name \\ "default", do: block) do
    quote do
      Module.put_attribute(__MODULE__, :content, :config)
      Module.put_attribute(__MODULE__, :configs, unquote(name))
      def config(unquote(name)) do
        var!(conf, Lambdapad.Blog) = %{}
        Map.merge(config_default(), unquote(block))
      end
      Module.put_attribute(__MODULE__, :content, nil)
    end
  end

  defmacro transform(name, do: block) do
    quote do
      Module.put_attribute(__MODULE__, :content, :transforms)
      Module.put_attribute(__MODULE__, :transforms, unquote(name))
      def transform(unquote(name)) do
        var!(conf, Lambdapad.Blog) = %{}
        unquote(block)
      end
      Module.put_attribute(__MODULE__, :content, nil)
    end
  end

  defmacro check(name, do: block) do
    quote do
      Module.put_attribute(__MODULE__, :content, :checks)
      Module.put_attribute(__MODULE__, :checks, unquote(name))
      def check(unquote(name)) do
        var!(conf, Lambdapad.Blog) = %{}
        unquote(block)
      end
      Module.put_attribute(__MODULE__, :content, nil)
    end
  end

  defmacro widget(name, do: block) do
    quote do
      Module.put_attribute(__MODULE__, :content, :widgets)
      Module.put_attribute(__MODULE__, :widgets, unquote(name))
      def widget(unquote(name)) do
        var!(conf, Lambdapad.Blog) = %{}
        Map.merge(widgets_default(), unquote(block))
        |> translate_from()
      end
      Module.put_attribute(__MODULE__, :content, nil)
    end
  end

  defmacro assets(name, do: block) do
    quote do
      Module.put_attribute(__MODULE__, :content, :assets)
      Module.put_attribute(__MODULE__, :assets, unquote(name))
      def assets(unquote(name)) do
        var!(conf, Lambdapad.Blog) = %{}
        unquote(block)
        |> translate_from()
      end
      Module.put_attribute(__MODULE__, :content, nil)
    end
  end

  defmacro assets(do: block) do
    quote do
      Module.put_attribute(__MODULE__, :content, :assets)
      Module.put_attribute(__MODULE__, :assets, "general")
      def assets("general") do
        var!(conf, Lambdapad.Blog) = %{}
        unquote(block)
      end
      Module.put_attribute(__MODULE__, :content, nil)
    end
  end

  defmacro pages(name, do: block) do
    quote do
      Module.put_attribute(__MODULE__, :content, :pages)
      Module.put_attribute(__MODULE__, :pages, unquote(name))
      def pages(unquote(name)) do
        var!(conf, Lambdapad.Blog) = %{}
        Map.merge(pages_default(), unquote(block))
        |> translate_from()
      end
      Module.put_attribute(__MODULE__, :content, nil)
    end
  end

  defmacro source([{key, value}]) do
    quote do
      @source {unquote(key), unquote(value)}
    end
  end

  defmacro set([{key, value}]) do
    quote do
      config = var!(conf, Lambdapad.Blog)
      new_conf = cond do
        @content == :config ->
          Map.put(config, unquote(key), unquote(value))
        @content == :assets ->
          Map.put(config, unquote(key), unquote(value))
        @content == :checks ->
          Map.put(config, unquote(key), unquote(value))
        @content == :transforms ->
          Map.put(config, unquote(key), unquote(value))
        @content == :widgets ->
          Map.put(config, unquote(key), unquote(value))
        @content == :pages ->
          Map.put(config, unquote(key), unquote(value))
      end
      var!(conf, Lambdapad.Blog) = new_conf
    end
  end

  defmacro extension("https:" <> _ = url) do
    url
    |> to_string()
    |> :httpc.request()
    |> case do
      {:ok, {{_http, 200, _ok}, _headers, content}} ->
        content
        |> to_string()
        |> Code.string_to_quoted!()

      {:ok, {{_http, code, error}, _headers, _content}} ->
        raise "Cannot retrieve extension:\n\t#{url}\n\t#{error} (#{code})"

      error ->
        raise "An error happended:\n#{inspect(error)}"
    end
  end

  defmacro extension(file) do
    file
    |> File.read!()
    |> Code.string_to_quoted!()
  end

  defmacro doc(_text), do: nil
end
