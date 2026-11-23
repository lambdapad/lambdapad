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
  alias Lambdapad.Generate.Assets.Esbuild
  alias Lambdapad.Generate.Assets.Npm
  alias Lambdapad.Generate.Assets.Tailwind

  @doc false
  def process(assets, workdir) do
    Enum.each(assets, fn {name, data} ->
      Cli.print_level2("Assets", name)
      src_path = Path.join([workdir, data[:from]])

      base_src_path =
        src_path
        |> Path.split()
        |> Enum.take_while(&(not String.contains?(&1, ~w"* ? [ ] { }")))
        |> Path.join()

      dst_path = Path.join([workdir, data[:to] || ""])

      Enum.each(Path.wildcard(src_path), fn file ->
        process_asset_file(data, file, base_src_path, dst_path)
      end)

      Cli.print_level2_ok()
    end)
  end

  defp process_asset_file(data, file, base_src_path, dst_path) do
    base_file = String.replace_prefix(file, base_src_path, "")
    print_file = get_print_file(base_file, file)

    case process_file(data, file, dst_path, base_file) do
      :ok ->
        Cli.print_level3(print_file)

      {:error, reason} ->
        Cli.print_error("Asset processing failed for #{print_file}: #{format_error(reason)}")
        Cli.halt(1)
    end
  end

  defp get_print_file("", file), do: Path.basename(file)
  defp get_print_file(base_file, _file), do: base_file

  defp process_file(%{tool: :esbuild} = data, src_file, dst_path, base_file) do
    Esbuild.run(data, src_file, dst_path, base_file)
  end

  defp process_file(%{tool: :tailwind} = data, src_file, dst_path, base_file) do
    Tailwind.run(data, src_file, dst_path, base_file)
  end

  defp process_file(%{tool: :npm} = data, src_file, dst_path, base_file) do
    Npm.run(data, src_file, dst_path, base_file)
  end

  defp process_file(_data, src_file, dst_path, base_file) do
    unless File.dir?(src_file) do
      dst_file = Path.join(dst_path, base_file)
      File.mkdir_p(Path.dirname(dst_file))
      File.cp!(src_file, dst_file)
    end

    :ok
  end

  defp format_error(137) do
    if :os.type() == {:unix, :darwin} do
      "exit code 137 (SIGKILL — binary may need codesign on macOS)"
    else
      "exit code 137 (SIGKILL)"
    end
  end

  defp format_error(code) when is_integer(code), do: "exit code #{code}"
  defp format_error(reason) when is_binary(reason), do: reason
  defp format_error(reason), do: inspect(reason)
end
