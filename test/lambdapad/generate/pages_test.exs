defmodule Lambdapad.Generate.PagesTest do
  use ExUnit.Case
  alias Lambdapad.Generate.Pages

  test "generate pages in Spanish" do
    File.rm_rf!("_output")

    cfg = %{
      "blog" => %{
        "url" => "http://localhost:8080/",
        "languages" => ["es"],
        "languages_path" => "gettext"
      }
    }

    pages = %{
      "dummy" => %{
        from: "about.md",
        uri: "/about/index.html",
        uri_type: :file,
        format: :eex,
        template: "hello.html.eex",
        var_name: "page"
      }
    }

    Pages.process(pages, cfg, __MODULE__, "test/support", "_output")
    assert File.dir?("_output/about")
    assert File.regular?("_output/about/index.html")
    content = File.read!("_output/about/index.html")

    assert """
           <title>Hola mundo</title>
           [languages: ["es"], languages_path: "gettext", url: "http://localhost:8080/"]
           ----------
           <h1>
           Hello</h1>
           <p>
           This is the code we are going to use for Hello!</p>

           """ =~ content

    File.rm_rf!("_output")
    :ok
  end

  test "generates a non-paginated index page listing every matching post" do
    File.rm_rf!("_output")

    cfg = %{"blog" => %{"url" => "", "languages" => ["en"], "languages_path" => "gettext"}}

    pages = %{
      "idx" => %{
        from: "widget_posts/*.md",
        headers: false,
        index: true,
        paginated: false,
        uri: "/posts/index.html",
        uri_type: :file,
        format: :eex,
        template: "pages_index.html.eex",
        var_name: "posts"
      }
    }

    Pages.process(pages, cfg, __MODULE__, "test/support", "_output")

    content = File.read!("_output/posts/index.html")
    assert content =~ "<li>hello</li>"
    assert content =~ "<li>world</li>"

    File.rm_rf!("_output")
  end

  test "paginates an index page and links pages together with prev/next" do
    File.rm_rf!("_output")

    cfg = %{"blog" => %{"url" => "", "languages" => ["en"], "languages_path" => "gettext"}}

    pages = %{
      "idx_paginated" => %{
        from: "widget_posts/*.md",
        headers: false,
        index: true,
        paginated: 1,
        uri: fn index, _vars -> "/posts/page-#{index}.html" end,
        uri_type: :file,
        format: :eex,
        template: "pages_paginated.html.eex",
        var_name: "posts"
      }
    }

    Pages.process(pages, cfg, __MODULE__, "test/support", "_output")

    page1 = File.read!("_output/posts/page-1.html")
    page2 = File.read!("_output/posts/page-2.html")

    assert page1 =~ "next: /posts/page-2.html"
    refute page1 =~ "prev:"
    assert page2 =~ "prev: /posts/page-1.html"
    refute page2 =~ "next:"

    File.rm_rf!("_output")
  end

  test "generates one page per source file when index is not set, with a per-file uri" do
    File.rm_rf!("_output")

    cfg = %{"blog" => %{"url" => "", "languages" => ["en"], "languages_path" => "gettext"}}

    pages = %{
      "single" => %{
        from: "widget_posts/*.md",
        headers: false,
        uri: "/posts/{{ post.id }}.html",
        uri_type: :file,
        format: :eex,
        template: "pages_single.html.eex",
        var_name: "post"
      }
    }

    Pages.process(pages, cfg, __MODULE__, "test/support", "_output")

    assert File.read!("_output/posts/hello.html") =~ "hello: <p>\nHello post content.</p>"
    assert File.read!("_output/posts/world.html") =~ "world: <p>\nWorld post content.</p>"

    File.rm_rf!("_output")
  end

  test "skips a page for languages other than the one configured for it" do
    File.rm_rf!("_output")

    cfg = %{
      "blog" => %{"url" => "", "languages" => ["en", "es"], "languages_path" => "gettext"}
    }

    pages = %{
      "only_es" => %{
        from: "widget_posts/hello.md",
        headers: false,
        language: "es",
        uri: "/{{language}}/only-es.html",
        uri_type: :file,
        format: :eex,
        template: "pages_single.html.eex",
        var_name: "post"
      }
    }

    Pages.process(pages, cfg, __MODULE__, "test/support", "_output")

    refute File.exists?("_output/en/only-es.html")
    assert File.exists?("_output/es/only-es.html")

    File.rm_rf!("_output")
  end
end
