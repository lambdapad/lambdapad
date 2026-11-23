defmodule Lambdapad.Cli.TuiTest do
  use ExUnit.Case, async: true
  alias Lambdapad.Cli.Tui

  test "slugify/1 normalizes accents, spaces, and punctuation" do
    assert Tui.slugify("Hello World!") == "hello-world"
    assert Tui.slugify("Cómo publicar en GitHub Pages") == "como-publicar-en-github-pages"
    assert Tui.slugify("  Under the Hood: Padmark & lpad  ") == "under-the-hood-padmark-lpad"
  end

  test "otp_version/0 returns a positive integer" do
    assert is_integer(Tui.otp_version())
    assert Tui.otp_version() > 0
  end

  test "supported?/0 returns a boolean" do
    assert is_boolean(Tui.supported?())
  end
end
