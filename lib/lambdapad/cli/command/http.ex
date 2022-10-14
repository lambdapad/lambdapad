defmodule Lambdapad.Cli.Command.Http do
  @moduledoc """
  HTTP CLI command is in charge of running an HTTP server you can ask
  for watching the whole website you just generated. It's a fast way
  to check that everything is on place.

  The parameters available let you to choose the PORT where to listen
  for the incoming connections.
  """
  use Lambdapad.Cli.Command

  alias Lambdapad.{Blog, Cli, Config, Http}
  alias Lambdapad.Cli.Command.Compile

  @default_port 8080
  @default_verbosity 1

  @impl Lambdapad.Cli.Command
  def options do
    [
      name: "http",
      about: "HTTP Server for fast checking",
      args: Cli.get_infile_options(),
      options: [
        port: [
          value_name: "PORT",
          short: "-p",
          long: "--port",
          help: "Port where to listen, by default it is 8080",
          parser: fn p ->
            case Integer.parse(p) do
              {port, ""} when port >= 1024 -> {:ok, port}
              {port, ""} -> {:error, "port must be greater than 1024, #{port} is invalid"}
              {_, _} -> {:error, "you have to provide a port number"}
            end
          end,
          required: false
        ]
      ]
    ]
  end

  @impl Lambdapad.Cli.Command
  def command(%{infile: lambdapad_file, port: port, rawargs: rawargs} = params) do
    workdir = Cli.cwd!(lambdapad_file)

    {:ok, mod} = Blog.Base.compile(lambdapad_file)
    {:ok, config} = Config.init(Blog.Base.get_configs(mod, rawargs), workdir)

    dir = Path.join([workdir, config["blog"]["output_dir"] || "site"])
    port = port || config["http"]["port"] || @default_port

    Http.start_server(port, dir)
    IO.puts([IO.ANSI.green(), "options", IO.ANSI.reset(), ": [q]uit or [r]ecompile"])

    if IO.gets("") == "r\n" do
      verbosity = params[:verbosity] || @default_verbosity
      Compile.command(%{infile: params[:infile], verbosity: verbosity, rawargs: rawargs})
      command(params)
    else
      :ok
    end
  end
end
