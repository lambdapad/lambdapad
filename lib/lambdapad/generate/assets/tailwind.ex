defmodule Lambdapad.Generate.Assets.Tailwind do
  @moduledoc """
  The tailwind CSS tool is helping us to use tailwind for handling our CSS
  files so we can use it in the configuration using the following config:

  ```elixir
  assets "css" do
    set from: "assets/**/*.css"
    set to: "site/"
    set tool: :tailwind
  end
  ```

  As you can see, we need only provide `tool` key with the content `:tailwind`.
  We can also provide more arguments for the tailwind command as follows:

  ```elixir
  assets "css" do
    set from: "assets/**/*.css"
    set to: "site/"
    set tool: :tailwind
    set tailwind: [
      # tailwind version to install
      version: "4.0.9",

      # tailwind path to install the binary
      path: "#{__DIR__}/bin/tailwind",

      # tailwind extra args
      extra_args: ~w(--optimize --minify)
    ]
  end
  ```
  """

  defp install_if_needed(data) do
    version = data[:tailwind][:version] || Tailwind.configured_version()
    Application.put_env(:tailwind, :version, version)

    bin_path =
      data[:tailwind][:path] || Path.join(File.cwd!(), Path.basename(Tailwind.bin_path()))

    Application.put_env(:tailwind, :path, bin_path)

    if File.exists?(bin_path) do
      :ok
    else
      try do
        Tailwind.install()
        :ok
      rescue
        reason in RuntimeError ->
          {:error, reason.message}
      end
    end
  end

  defp run_tailwind(data, src_file, dst_path, base_file) do
    extra_args = data[:tailwind][:extra_args] || []
    dst_file = Path.join(dst_path, base_file)
    args = ["--input=#{src_file}", "--output=#{dst_file}" | extra_args]

    opts = [
      cd: File.cwd!(),
      stderr_to_stdout: true
    ]

    Tailwind.bin_path()
    |> System.cmd(args, opts)
    |> case do
      {_, 0} -> :ok
      {reason, code} -> {:error, {reason, code}}
    end
  end

  @doc false
  def run(data, src_file, dst_path, base_file) do
    #  NOTE: avoid getting logs from tailwind
    Logger.put_module_level(Tailwind, :none)

    with :ok <- install_if_needed(data) do
      run_tailwind(data, src_file, dst_path, base_file)
    end
  end
end
