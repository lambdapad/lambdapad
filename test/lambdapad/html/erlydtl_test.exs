defmodule Lambdapad.Html.ErlydtlTest do
  use ExUnit.Case
  alias Lambdapad.Html
  alias Lambdapad.Html.Erlydtl

  @workdir Path.join(__DIR__, "../../support")

  @vars [
    {"blog", [{"url", "http://example.com"}]},
    {"posts", [[{"title", "Hello"}]]},
    {"lambdapad", [{"name", "Lambdapad"}, {"vsn", "0.12.0"}]}
  ]

  @config [
    {"widgets", [{"en", [{"sidebar", "SIDEBAR CONTENT"}]}]},
    {"language", "en"}
  ]

  test "renders blog/lambdapad variables, a for loop over posts, and a widget tag" do
    module = Erlydtl.init(:page, "erlydtl main", "erlydtl_main.html", @workdir)
    html = Html.render(@vars, module, @config)

    assert html =~ "Blog: http://example.com"
    assert html =~ "Post: Hello"
    assert html =~ "Generator: Lambdapad 0.12.0"
    assert html =~ "Widget: SIDEBAR CONTENT"
  end

  test "init/4 caches the compiled module: calling it twice returns the same module" do
    module1 = Erlydtl.init(:page, "erlydtl main", "erlydtl_main.html", @workdir)
    module2 = Erlydtl.init(:page, "erlydtl main", "erlydtl_main.html", @workdir)

    assert module1 == module2
  end

  test "raises when the widget tag references a widget missing for the current language" do
    module = Erlydtl.init(:page, "erlydtl main", "erlydtl_main.html", @workdir)
    config = [{"widgets", [{"en", []}]}, {"language", "en"}]

    assert_raise RuntimeError, ~r/widget "sidebar" \(locale en\) not found!/, fn ->
      Html.render(@vars, module, config)
    end
  end
end
