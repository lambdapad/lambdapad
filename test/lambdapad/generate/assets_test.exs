defmodule Lambdapad.Generate.AssetsTest do
  use ExUnit.Case
  alias Lambdapad.Generate.Assets

  setup do
    dir =
      Path.join(System.tmp_dir!(), "lambdapad_assets_test_#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join(dir, "assets"))
    File.write!(Path.join(dir, "assets/style.css"), "body { color: red; }")

    {:ok, dir: dir}
  end

  test "copies matching files from `from` to `to` when no tool is configured", %{dir: dir} do
    assets = %{"css" => %{from: "assets/*.css", to: "site/css"}}

    Assets.process(assets, dir)

    assert File.read!(Path.join(dir, "site/css/style.css")) == "body { color: red; }"
  end

  test "does not copy directories matched by the wildcard", %{dir: dir} do
    File.mkdir_p!(Path.join(dir, "assets/subdir"))
    assets = %{"all" => %{from: "assets/*", to: "site"}}

    Assets.process(assets, dir)

    assert File.regular?(Path.join(dir, "site/style.css"))
    refute File.exists?(Path.join(dir, "site/subdir"))
  end

  test "dispatches to the esbuild tool when tool: :esbuild is set", %{dir: dir} do
    assets = %{
      "js" => %{
        from: "assets/*.css",
        to: "site/css",
        tool: :esbuild,
        esbuild: %{path: System.find_executable("echo")}
      }
    }

    Assets.process(assets, dir)
  end
end
