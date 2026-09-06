defmodule Lambdapad.Html.EexTest do
  use ExUnit.Case
  alias Lambdapad.Html.Eex, as: HtmlEex

  @workdir Path.join(__DIR__, "../../support")

  test "a template can include another template with render/2" do
    module = HtmlEex.init(:page, "partial main", "partial_main.html.eex", @workdir)

    assert {:ok, iodata} = module.render(language: "en", widgets: [])
    assert IO.iodata_to_binary(iodata) =~ "included content"
  end
end
