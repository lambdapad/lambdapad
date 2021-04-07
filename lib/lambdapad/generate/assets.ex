defmodule Lambdapad.Generate.Assets do
  require Logger

  def process(assets, workdir) do
    Enum.each(assets, fn {name, data} ->
      Logger.debug("copying data based on #{inspect(name)} => #{inspect(data)}")
      src_path = Path.join([workdir, data[:from]])
      Logger.debug("src_path => #{src_path}")
      base_src_path =
        src_path
        |> Path.split()
        |> Enum.take_while(& not String.contains?(&1, ["*", "?", "[", "]", "{", "}"]))
        |> Path.join()

      Logger.debug("base_src_path => #{base_src_path}")
      dst_path = Path.join([workdir, data[:to]])
      Logger.debug("dst_path => #{dst_path}")
      Enum.each(Path.wildcard(src_path), fn file ->
        dst_file = String.replace_prefix(file, base_src_path, dst_path)
        Logger.info("copying #{file} to #{dst_file}")
        File.mkdir_p(Path.dirname(dst_file))
        File.cp(file, dst_file)
      end)
    end)
  end
end
