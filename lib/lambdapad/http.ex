defmodule Lambdapad.Http do
  @moduledoc """
  The HTTP module for Lambdapad is responsible to start a HTTP server and
  provide an easy way to retrieve the files via HTTP. This way we can check
  the generate site through a real HTTP connection and using URIs.

  DON'T USE IT FOR PRODUCTION. Even if it's using cowboy and it could be
  handling a lot of requests, it's not intended for production and it was
  not checked for security, I mean, it could expose your filesystem to
  Internet, which is never desirable.
  """
  require Logger

  @doc """
  Start the HTTP server using cowboy.
  """
  def start_server(port, dir) do
    IO.puts(["HTTP Server on ", IO.ANSI.yellow(), "http://localhost:#{port}/", IO.ANSI.reset()])
    IO.puts(["Reading from ", IO.ANSI.green(), dir, IO.ANSI.reset()])
    opts = %{env: %{dispatch: dispatch(dir)}}
    port_info = [:inet, port: port]

    case :cowboy.start_clear(__MODULE__, port_info, opts) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
      {:error, error} -> throw({:error, error})
    end
  end

  defp dispatch(dir) do
    :cowboy_router.compile(
      _: [
        {"/[...]", __MODULE__, [dir]}
      ]
    )
  end

  @doc false
  def init(%{peer: {remote_ip, _remote_port}, path: path} = req, [dir]) do
    file = Path.join([dir, path])

    if File.regular?(file) do
      {first, second, _} = :cow_mimetypes.all(file)
      headers = %{"content-type" => "#{first}/#{second}"}
      req = :cowboy_req.reply(200, headers, File.read!(file), req)
      IO.puts("#{:inet.ntoa(remote_ip)} \"#{req.method} #{req.path}\" 200")
      {:ok, req, dir}
    else
      file = Path.join([file, "index.html"])
      headers = %{"content-type" => "text/html"}

      if File.regular?(file) do
        req = :cowboy_req.reply(200, headers, File.read!(file), req)
        IO.puts("#{:inet.ntoa(remote_ip)} \"#{req.method} #{req.path}\" 200")
        {:ok, req, dir}
      else
        req = :cowboy_req.reply(404, headers, req)
        IO.puts("#{:inet.ntoa(remote_ip)} \"#{req.method} #{req.path}\" 404")
        {:ok, req, dir}
      end
    end
  end
end
