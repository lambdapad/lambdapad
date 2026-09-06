defmodule Lambdapad.Generate.WidgetsTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Lambdapad.Generate.Widgets

  @workdir Path.join(__DIR__, "../../support")
  @config %{"blog" => %{"languages" => ["en"], "languages_path" => "gettext"}}

  test "process/4 renders the template once per language, using var_name for the pages list" do
    widgets = %{
      "recent" => %{
        format: :eex,
        template: "widget_recent.html.eex",
        from: "widget_posts/*.md",
        var_name: "posts"
      }
    }

    assert %{"en" => %{"recent" => iodata}} = Widgets.process(widgets, @config, nil, @workdir)
    html = IO.iodata_to_binary(iodata)

    assert html =~ "<li>hello</li>"
    assert html =~ "<li>world</li>"
  end

  test "get_vars falls back to \"pages\" and warns when :plain is used with a list of pages" do
    widgets = %{
      "fallback" => %{
        format: :eex,
        template: "widget_plain_fallback.html.eex",
        from: "widget_posts/*.md",
        var_name: :plain
      }
    }

    previous = Application.get_env(:lambdapad, :loglevel)
    Application.put_env(:lambdapad, :loglevel, 2)

    output =
      capture_io(fn ->
        assert %{"en" => %{"fallback" => iodata}} =
                 Widgets.process(widgets, @config, nil, @workdir)

        assert IO.iodata_to_binary(iodata) =~ "<li>hello</li>"
      end)

    case previous do
      nil -> Application.delete_env(:lambdapad, :loglevel)
      level -> Application.put_env(:lambdapad, :loglevel, level)
    end

    assert output =~ "widget cannot use :plain with lists, fallback to var_name \"pages\""
  end

  test "get_vars uses :plain directly when transform_on_page produces a flat proplist" do
    widgets = %{
      "plain" => %{
        format: :eex,
        template: "widget_plain.html.eex",
        from: "widget_posts/*.md",
        var_name: :plain,
        transform_on_page: fn _pages, _config -> [total: 2] end
      }
    }

    assert %{"en" => %{"plain" => iodata}} = Widgets.process(widgets, @config, nil, @workdir)
    assert IO.iodata_to_binary(iodata) =~ "Total: 2"
  end
end
