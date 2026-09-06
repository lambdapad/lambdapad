defmodule Lambdapad.Html.Erlydtl.FiltersTest do
  use ExUnit.Case
  alias Lambdapad.Html.Erlydtl.Filters

  @markdown_dir "test/support/markdown"

  defp markdown(name) do
    File.read!(Path.join(@markdown_dir, "#{name}.md"))
  end

  describe "markdown_to_html/1" do
    test "returns an empty string for :undefined" do
      assert Filters.markdown_to_html(:undefined) == ""
    end

    test "wraps the rendered HTML in a {:safe, html} tuple for ErlyDTL" do
      assert Filters.markdown_to_html(markdown("paragraph")) ==
               {:safe,
                "<p>\nThis is a simple paragraph.</p>\n<p>\nThis is a second paragraph with a\nsoft line break in the middle.</p>\n"}
    end

    test "renders fenced code blocks with the language as a class" do
      assert Filters.markdown_to_html(markdown("code")) ==
               {:safe,
                "<p>\nUse the <code class=\"inline\">String.trim/1</code> function for this.</p>\n<pre><code class=\"elixir\">defmodule Example do\n  def hello, do: :world\nend</code></pre>\n"}
    end

    test "escapes special characters the same way as Lambdapad.Generate.Sources" do
      alias Lambdapad.Generate.Sources
      text = markdown("escaping")

      assert {:safe, html} = Filters.markdown_to_html(text)

      assert html ==
               Sources.get_file(Path.join(@markdown_dir, "escaping.md"), false, false)["content"]
    end
  end
end
