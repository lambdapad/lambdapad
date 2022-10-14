defmodule Lambdapad.Generate.Assets do
  @moduledoc """
  Perform the copy of the assets found by the `from` configuration provided
  and it will copy them to the `to` configuration provided.

  Basically, if we provide this configuration:

  ```
  assets do
    set from: "assets/*.css"
    set to: "site/css"
  end
  ```

  This is going to copy all of the files found by the wildcard `assets/*.css`
  to the target `site/css`.
  """
  alias Lambdapad.Cli

  @doc false
  def process(assets, workdir) do
    Enum.each(assets, fn {name, data} ->
      Cli.print_level2("Assets", name)
      src_path = Path.join([workdir, data[:from]])

      base_src_path =
        src_path
        |> Path.split()
        |> Enum.take_while(&(not String.contains?(&1, ["*", "?", "[", "]", "{", "}"])))
        |> Path.join()

      dst_path = Path.join([workdir, data[:to]])

      Enum.each(Path.wildcard(src_path), fn file ->
        dst_file = String.replace_prefix(file, base_src_path, dst_path)
        base_file = String.replace_prefix(file, base_src_path, "")
        Cli.print_level3(base_file)
        File.mkdir_p(Path.dirname(dst_file))
        File.cp(file, dst_file)
      end)

      Cli.print_level2_ok()
    end)
  end
end
