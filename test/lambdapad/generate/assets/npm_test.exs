defmodule Lambdapad.Generate.Assets.NpmTest do
  use ExUnit.Case
  alias Lambdapad.Generate.Assets.Npm

  setup do
    dir = Path.join(System.tmp_dir!(), "lambdapad_npm_test_#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)

    File.write!(
      Path.join(dir, "package.json"),
      ~s({"name": "lambdapad-npm-test", "version": "1.0.0"})
    )

    {:ok, dir: dir}
  end

  test "runs `npm i` inside the package.json directory, not the caller's cwd", %{dir: dir} do
    cwd_before = File.cwd!()

    assert :ok = Npm.run(%{}, Path.join(dir, "package.json"), nil, nil)

    assert File.cwd!() == cwd_before
    refute File.exists?(Path.join(cwd_before, "node_modules"))
  end

  test "returns an error tuple when the command exits with a non-zero status", %{dir: dir} do
    data = %{npm: %{path: System.find_executable("false")}}

    assert {:error, 1} = Npm.run(data, Path.join(dir, "package.json"), nil, nil)
  end
end
