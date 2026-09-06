defmodule Lambdapad.Generate.SourcesTest do
  use ExUnit.Case
  alias Lambdapad.Generate.Sources

  @markdown_dir "test/support/markdown"

  defp render(name) do
    Sources.get_file(Path.join(@markdown_dir, "#{name}.md"), false, false)
  end

  describe "content (Markdown -> HTML, via Padmark.as_html/2)" do
    test "renders paragraphs, including soft line breaks" do
      assert render("paragraph")["content"] ==
               "<p>\nThis is a simple paragraph.</p>\n<p>\nThis is a second paragraph with a\nsoft line break in the middle.</p>\n"
    end

    test "renders headings h1 through h6" do
      assert render("headings")["content"] ==
               "<h1>\nHeading 1</h1>\n<h2>\nHeading 2</h2>\n<h3>\nHeading 3</h3>\n<h4>\nHeading 4</h4>\n<h5>\nHeading 5</h5>\n<h6>\nHeading 6</h6>\n"
    end

    test "renders emphasis (italic, bold, bold+italic)" do
      assert render("emphasis")["content"] ==
               "<p>\nThis has <em>italic</em>, <strong>bold</strong> and <strong><em>bold italic</em></strong> text.</p>\n"
    end

    test "renders links, including titles and autolinks" do
      assert render("links")["content"] ==
               "<p>\nCheck <a href=\"https://example.com/page\" title=\"Example Title\">this link</a> for more info.</p>\n<p>\nAlso visit <a href=\"https://example.com/auto\">https://example.com/auto</a> directly.</p>\n"
    end

    test "renders images with alt and title" do
      assert render("images")["content"] ==
               "<p>\nHere is an image:</p>\n<p>\n  <img src=\"/images/photo.png\" alt=\"Alt text for image\" title=\"Photo title\">\n</p>\n"
    end

    test "renders unordered and ordered lists, including nesting" do
      assert render("lists")["content"] ==
               "<p>\nUnordered list:</p>\n<ul>\n  <li>\nFirst item  </li>\n  <li>\nSecond item    <ul>\n      <li>\nNested item      </li>\n    </ul>\n  </li>\n  <li>\nThird item  </li>\n</ul>\n<p>\nOrdered list:</p>\n<ol>\n  <li>\nStep one  </li>\n  <li>\nStep two  </li>\n  <li>\nStep three  </li>\n</ol>\n"
    end

    test "renders inline code and fenced code blocks with a language class" do
      assert render("code")["content"] ==
               "<p>\nUse the <code class=\"inline\">String.trim/1</code> function for this.</p>\n<pre><code class=\"elixir\">defmodule Example do\n  def hello, do: :world\nend</code></pre>\n"
    end

    test "renders blockquotes" do
      assert render("blockquote")["content"] ==
               "<blockquote>\n  <p>\nThis is a quote.  </p>\n  <p>\nIt has two paragraphs.  </p>\n</blockquote>\n"
    end

    test "renders horizontal rules" do
      assert render("hr")["content"] ==
               "<p>\nBefore the rule.</p>\n<hr class=\"thin\">\n<p>\nAfter the rule.</p>\n"
    end

    test "renders GFM tables (extension: [gfm_tables: true])" do
      assert render("table")["content"] ==
               "<table>\n  <thead>\n    <tr>\n      <th style=\"text-align: left;\">\nName      </th>\n      <th style=\"text-align: left;\">\nValue      </th>\n    </tr>\n  </thead>\n  <tbody>\n    <tr>\n      <td style=\"text-align: left;\">\nAlpha      </td>\n      <td style=\"text-align: left;\">\n1      </td>\n    </tr>\n    <tr>\n      <td style=\"text-align: left;\">\nBeta      </td>\n      <td style=\"text-align: left;\">\n2      </td>\n    </tr>\n  </tbody>\n</table>\n"
    end

    test "renders footnotes (extension: [footnotes: true])" do
      content = render("footnote")["content"]

      # The backref tag's attribute order comes from Erlang map iteration,
      # which is unspecified and has changed across OTP releases, so match
      # it with a regex instead of a fixed attribute order.
      assert content =~
               "<p>\nHere is a statement with a footnote<a href=\"#fn:1\" id=\"fnref:1\" class=\"footnote\" title=\"see footnote\">1</a>.</p>\n<div class=\"footnotes\">\n  <hr>\n  <ol>\n    <li id=\"fn:1\">\n"

      assert content =~
               ~r/<a title="return to article" (?:href="#fnref:1" class="reversefootnote"|class="reversefootnote" href="#fnref:1")>&#x21A9;<\/a>/

      assert content =~
               "      <p>\nThis is the footnote text.      </p>\n    </li>\n  </ol>\n</div>\n"
    end

    test "renders subscript and superscript (extension: [sub_sup: true])" do
      assert render("subsup")["content"] ==
               "<p>\nWater is H  <sub>\n2  </sub>\nO and energy is E=mc  <sup>\n2  </sup>\n.</p>\n"
    end

    test "passes raw HTML blocks through untouched" do
      assert render("raw_html")["content"] ==
               "<p>\nBefore raw html.</p>\n<div class=\"custom\">\n    <span>Raw HTML block</span></div>\n<p>\nAfter raw html.</p>\n"
    end

    test "renders a hard line break from a trailing double space" do
      assert render("linebreak")["content"] ==
               "<p>\nFirst line with hard break.  <br>\nSecond line right after.</p>\n"
    end

    test "does not apply smart punctuation (smartypants: false): quotes and dashes stay literal" do
      assert render("smartypants")["content"] ==
               "<p>\nHe said &quot;hello&quot; and it&#39;s a test -- really -- with an ellipsis...</p>\n"
    end

    test "escapes special characters in plain text" do
      assert render("escaping")["content"] =~
               "This text has special chars: &lt; &gt; &amp; &quot; &#39; to escape."
    end

    test "escapes special characters inside an image alt attribute" do
      assert render("escaping")["content"] =~
               "alt=\"Alt with &quot;quotes&quot; &amp; &lt;brackets&gt;\""
    end

    # Regression test for GHSA-52mm-h59v-f3c7 (CVE-2026-48591): earmark did not
    # escape `<`, `>` and `&` inside a link/image title attribute, so a title
    # containing those characters broke out of the attribute early (stored XSS).
    # Padmark's _make_att1 now escapes the whole attribute value, closing that hole.
    test "fixes the stored-XSS advisory: link title attributes are fully escaped" do
      assert render("escaping")["content"] =~
               "title=\"Title with &quot;quotes&quot; &amp; &lt;tags&gt;\""

      refute render("escaping")["content"] =~ "<tags>"
    end

    test "content and the ErlyDTL markdown_to_html filter agree" do
      text = File.read!(Path.join(@markdown_dir, "escaping.md"))
      assert {:safe, html} = Lambdapad.Html.Erlydtl.Filters.markdown_to_html(text)
      assert html == render("escaping")["content"]
    end
  end

  describe "content_text (Markdown -> unstyled plain text, via Padmark.Parser.as_ast/2)" do
    test "keeps only the text of a paragraph" do
      assert render("paragraph")["content_text"] ==
               "This is a simple paragraph.This is a second paragraph with a\nsoft line break in the middle."
    end

    test "strips heading markup, concatenating the text of every heading" do
      assert render("headings")["content_text"] ==
               "Heading 1Heading 2Heading 3Heading 4Heading 5Heading 6"
    end

    test "strips emphasis markup" do
      assert render("emphasis")["content_text"] == "This has italic, bold and bold italic text."
    end

    test "keeps link text but drops the href" do
      assert render("links")["content_text"] ==
               "Check this link for more info.Also visit https://example.com/auto directly."
    end

    test "drops images entirely, including the alt text" do
      assert render("images")["content_text"] == "Here is an image:"
    end

    test "concatenates list item text without separators" do
      assert render("lists")["content_text"] ==
               "Unordered list:First itemSecond itemNested itemThird itemOrdered list:Step oneStep twoStep three"
    end

    test "keeps code text without the fences or the language" do
      assert render("code")["content_text"] ==
               "Use the String.trim/1 function for this.defmodule Example do\n  def hello, do: :world\nend"
    end

    test "strips table structure, concatenating cell text" do
      assert render("table")["content_text"] == "NameValueAlpha1Beta2"
    end

    test "keeps the footnote reference marker and definition text as literal Markdown" do
      assert render("footnote")["content_text"] ==
               "Here is a statement with a footnote[^1].[^1]: This is the footnote text."
    end

    test "keeps the sub/superscript markers as literal Markdown" do
      assert render("subsup")["content_text"] == "Water is H~2~O and energy is E=mc^2^."
    end

    test "does not crash when the parser reports a warning (e.g. an unclosed backtick)" do
      assert render("unclosed_backtick")["content_text"] ==
               "This paragraph has an unclosed backtick: `oops"
    end

    test "keeps raw HTML blocks as literal text" do
      assert render("raw_html")["content_text"] ==
               "Before raw html.  <span>Raw HTML block</span>After raw html."
    end
  end

  describe "excerpt handling (<!-- more --> marker)" do
    test "splits excerpt from the rest, rendering both content and content_text" do
      data = Sources.get_file(Path.join(@markdown_dir, "excerpt.md"), true, true)

      assert data["excerpt_raw"] == "This is the excerpt paragraph.\n"
      assert data["excerpt_html"] == "<p>\nThis is the excerpt paragraph.</p>\n"
      assert data["excerpt"] == "This is the excerpt paragraph."

      assert data["content"] ==
               "<p>\nThis is the excerpt paragraph.</p>\n<!-- more -->\n<p>\nThis is the rest of the content.</p>\n"

      assert data["content_text"] ==
               "This is the excerpt paragraph. more This is the rest of the content."
    end
  end
end
