defmodule Lambdapad do
  @moduledoc """
  Documentation for `Lambdapad`.
  """
  defmacro blog(do: block) do
    quote do
      defmodule Lambdapad.Blog do
        @moduledoc false
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

        @doc false
        def sources, do: @source

        @doc false
        def configs, do: Lambdapad.Blog.Base.configs(@configs)

        @doc false
        def transforms, do: Lambdapad.Blog.Base.transforms(@transforms)

        @doc false
        def checks, do: Lambdapad.Blog.Base.checks(@checks)

        @doc false
        def widgets, do: Lambdapad.Blog.Base.widgets(@widgets)

        @doc false
        def pages, do: Lambdapad.Blog.Base.pages(@pages)

        @doc false
        def assets, do: Lambdapad.Blog.Base.assets(@assets)
      end
    end
  end

  defmacro __using__(_opts) do
    quote do
      @doc false
      def config("default") do
        %{
          format: :toml,
          from: "config.toml",
          transform_from_pages: nil
        }
      end

      @doc false
      def assets("general") do
        %{
          from: "assets/**",
          to: "site/"
        }
      end

      @doc false
      def assets(_), do: nil

      @doc false
      def sources(), do: %{}

      @doc false
      def source(key) do
        sources()[key]
      end

      @doc false
      def transform(_), do: nil

      @doc false
      def check(_), do: nil

      @doc false
      def widget(_), do: nil

      @doc false
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

      defoverridable config: 1,
                     assets: 1,
                     sources: 0,
                     transform: 1,
                     check: 1,
                     widget: 1,
                     pages: 1
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

      true = @content in ~w[ config assets checks transforms widgets pages ]a
      var!(conf, Lambdapad.Blog) = Map.put(config, unquote(key), unquote(value))
    end
  end

  defmacro set_env([{key, value}]) do
    quote do
      config = var!(conf, Lambdapad.Blog)
      key = unquote(key)

      true = @content in ~w[ config assets checks transforms widgets pages ]a
      env = Map.put(config[:env] || %{}, key, unquote(value))
      var!(conf, Lambdapad.Blog) = Map.put(config, :env, env)
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
