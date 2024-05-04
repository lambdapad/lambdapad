defmodule Lambdapad.Generate.PagesTest do
  use ExUnit.Case
  alias Lambdapad.Generate.Pages

  test "generate pages in Spanish" do
    File.rm_rf!("_output")

    cfg = %{
      "blog" => %{
        "url" => "http://localhost:8080/",
        "languages" => ["es"],
        "languages_path" => "test/support/gettext"
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
           [languages: ["es"], languages_path: "test/support/gettext", url: "http://localhost:8080/"]
           ----------
           <h1>
           Hello</h1>
           <p>
           This is the code we are going to use for Hello!</p>

           """ =~ content

    File.rm_rf!("_output")
    :ok
  end
end
