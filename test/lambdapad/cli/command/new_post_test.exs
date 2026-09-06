defmodule Lambdapad.Cli.Command.NewPostTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Lambdapad.Cli.Command.NewPost

  @infile Path.join(__DIR__, "../../../support/cli_project/lambdapad.exs")
  @workdir Path.dirname(@infile)

  @bound_infile Path.join(__DIR__, "../../../support/new_post_project/lambdapad.exs")
  @bound_workdir Path.dirname(@bound_infile)

  test "creates a post file with the default headers, bindings applied, and a Lorem Ipsum body" do
    params = %{
      name: "my-post",
      infile: @infile,
      rawargs: [],
      date: "2026-01-05",
      bind: [{"title", "Hello World"}],
      "posts-dir": nil,
      interactive: false,
      loglevel: 1
    }

    capture_io(fn -> NewPost.command(params) end)

    path = Path.join(@workdir, "posts/2026/01/05/my-post.md")
    assert File.regular?(path)

    content = File.read!(path)
    assert content =~ "id        : my-post"
    assert content =~ "date      : 2026-1-5"
    assert content =~ "Lorem Ipsum"
    assert content =~ "<!--more-->"

    File.rm_rf!(Path.join(@workdir, "posts"))
  end

  test "fills a header from a bind value when configured with a template_headers pattern" do
    params = %{
      name: "bound-post",
      infile: @bound_infile,
      rawargs: [],
      date: "2026-01-05",
      bind: [{"title", "Hello World"}],
      "posts-dir": nil,
      interactive: false,
      loglevel: 1
    }

    capture_io(fn -> NewPost.command(params) end)

    path = Path.join(@bound_workdir, "posts/2026/01/05/bound-post.md")
    content = File.read!(path)
    assert content =~ "title: Hello World"

    File.rm_rf!(Path.join(@bound_workdir, "posts"))
  end

  test "halts with the user-interrupt code when cancelling an interactive prompt" do
    params = %{
      name: "cancelled-post",
      infile: @infile,
      rawargs: [],
      date: nil,
      bind: [],
      "posts-dir": nil,
      interactive: true,
      loglevel: 1
    }

    assert catch_throw(capture_io("c\n", fn -> NewPost.command(params) end)) == {:halt, 137}

    refute File.exists?(Path.join(@workdir, "posts"))
  end
end
