defmodule Lambdapad.Generate.Assets.Esbuild do
  @moduledoc """
  Handling assets using esbuild tool. These assets will be handled one by one,
  as they are put in the configuration. The configuration should be something
  like:

  ```elixir
  assets "js" do
    set from: "assets/**/*.js"
    set to: "site/"
    set tool: :esbuild
  end
  ```

  As you can see, we need only to provide the `tool` configuration. But we can
  do even further configurations providing the key `esbuild`:

  ```elixir
  assets "js" do
    set from: "assets/**/*.js"
    set to: "site/"
    set tool: :esbuild
    set esbuild: [
      # esbuild version to be in use
      version: "0.25.0",

      # esbuild path for the binary
      path: "#{__DIR__}/bin/esbuild",

      # esbuild target option
      target: "es2016",

      # esbuild extra args for command
      extra_args: ~w(--verbose)
    ]
  end
  ```
  """

  defp install_if_needed(data) do
    version = data[:esbuild][:version] || Esbuild.configured_version()
    Application.put_env(:esbuild, :version, version)

    bin_path = data[:esbuild][:path] || Path.join(File.cwd!(), Path.basename(Esbuild.bin_path()))
    Application.put_env(:esbuild, :path, bin_path)

    if File.exists?(bin_path) do
      :ok
    else
      try do
        Esbuild.install()
        :ok
      rescue
        reason in RuntimeError ->
          {:error, reason.message}
      end
    end
  end

  defp run_esbuild(data, src_file, dst_path, base_file) do
    target = data[:esbuild][:target] || "es2016"
    extra_args = data[:esbuild][:extra_args] || []
    dst_path = Path.dirname(Path.join(dst_path, base_file))
    args = [src_file, "--bundle", "--target=#{target}", "--outdir=#{dst_path}" | extra_args]

    opts = [
      cd: File.cwd!(),
      stderr_to_stdout: true
    ]

    Esbuild.bin_path()
    |> System.cmd(args, opts)
    |> case do
      {_, 0} -> :ok
      {reason, code} -> {:error, {reason, code}}
    end
  end

  @doc false
  def run(data, src_file, dst_path, base_file) do
    #  NOTE: avoid getting logs from esbuild
    Logger.put_module_level(Esbuild.NpmRegistry, :none)

    with :ok <- install_if_needed(data) do
      run_esbuild(data, src_file, dst_path, base_file)
    end
  end
end
