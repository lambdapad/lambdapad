defmodule Lambdapad.Html.Erlydtl.FiltersTest do
  use ExUnit.Case
  alias Lambdapad.Html.Erlydtl.Filters

  @markdown_dir "test/support/markdown"

  defp markdown(name) do
    File.read!(Path.join(@markdown_dir, "#{name}.md"))
  end

  describe "read_file/1" do
    test "returns an empty string for :undefined" do
      assert Filters.read_file(:undefined) == ""
    end

    test "reads the whole file relative to the configured workdir" do
      previous = Application.get_env(:lambdapad, :workdir)
      Application.put_env(:lambdapad, :workdir, "test/support")

      assert Filters.read_file("read_file_fixture.txt") ==
               "line one\nline two\nline three\nline four\nline five\n"

      case previous do
        nil -> Application.delete_env(:lambdapad, :workdir)
        dir -> Application.put_env(:lambdapad, :workdir, dir)
      end
    end

    test "reads an absolute path directly, ignoring the workdir" do
      abs = Path.absname("test/support/read_file_fixture.txt")
      assert Filters.read_file(abs) =~ "line one"
    end
  end

  describe "read_file/2" do
    setup do
      previous = Application.get_env(:lambdapad, :workdir)
      Application.put_env(:lambdapad, :workdir, "test/support")

      on_exit(fn ->
        case previous do
          nil -> Application.delete_env(:lambdapad, :workdir)
          dir -> Application.put_env(:lambdapad, :workdir, dir)
        end
      end)

      :ok
    end

    test "returns an empty string for :undefined" do
      assert Filters.read_file(:undefined, "1:2") == ""
    end

    test "reads a first:last range" do
      assert Filters.read_file("read_file_fixture.txt", "2:4") == [
               "line two\n",
               "line three\n",
               "line four\n"
             ]
    end

    test "reads from the start when first is omitted" do
      assert Filters.read_file("read_file_fixture.txt", ":2") == [
               "line one\n",
               "line two\n"
             ]
    end

    test "reads to the end when last is omitted" do
      assert Filters.read_file("read_file_fixture.txt", "4:") == [
               "line four\n",
               "line five\n"
             ]
    end

    test "reads the whole file with a bare colon" do
      assert Filters.read_file("read_file_fixture.txt", ":") == [
               "line one\n",
               "line two\n",
               "line three\n",
               "line four\n",
               "line five\n"
             ]
    end

    test "throws for a lines spec without a colon" do
      assert catch_throw(Filters.read_file("read_file_fixture.txt", "5")) ==
               {:lines_spec, "5"}
    end
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
