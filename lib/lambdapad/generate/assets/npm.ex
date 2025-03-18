defmodule Lambdapad.Generate.Assets.Npm do
  @moduledoc """
  The NPM tool let us to handle the installation of extra dependencies
  for JavaScript inside of our project. We have only to specify:

  ```elixir
  assets "node_modules" do
    set from: "package.json"
    set tool: :npm
  end
  ```

  In difference to `esbuild` and `tailwind` the `npm` tool cannot be
  installed by `lpad`, but you can define the path where it's placed
  (if that's not in the PATH for the system):

  ```elixir
  assets "node_modules" do
    set from: "package.json"
    set tool: :npm
    set npm: [
      path: "/usr/bin/npm"
    ]
  end
  ```

  Note that it's going to run only: `npm i`.
  """
  alias Lambdapad.Cli

  @doc false
  def run(data, package_json_path, _dst_path, _package_json_file) do
    path = Path.dirname(package_json_path)
    args = ["i", path | data[:npm][:extra_args] || []]

    opts = [
      cd: File.cwd!(),
      stderr_to_stdout: true
    ]

    (data[:npm][:path] || "npm")
    |> System.cmd(args, opts)
    |> case do
      {output, 0} ->
        Cli.print_level3_multiline(output)
        :ok

      {output, code} ->
        Cli.print_level3_multiline(output)
        {:error, code}
    end
  end
end
