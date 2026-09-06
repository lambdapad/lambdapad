defmodule Lambdapad.Generate.Assets.TailwindTest do
  use ExUnit.Case
  alias Lambdapad.Generate.Assets.Tailwind

  # Both tests point `tailwind.path` at a real, already-existing binary so
  # `install_if_needed/1` takes its "already installed" branch and no
  # network download is ever attempted.

  test "runs the configured binary and reports success on a zero exit status" do
    data = %{tailwind: %{path: System.find_executable("echo")}}

    assert :ok = Tailwind.run(data, "app.css", System.tmp_dir!(), "app.css")
  end

  test "reports an error tuple on a non-zero exit status" do
    data = %{tailwind: %{path: System.find_executable("false")}}

    assert {:error, 1} = Tailwind.run(data, "app.css", System.tmp_dir!(), "app.css")
  end
end
