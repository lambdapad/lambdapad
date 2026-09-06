defmodule Lambdapad.Http do
  @moduledoc """
  The HTTP module for Lambdapad is responsible to start a HTTP server and
  provide an easy way to retrieve the files via HTTP. This way we can check
  the generate site through a real HTTP connection and using URIs.

  DON'T USE IT FOR PRODUCTION. Even if it's using Bandit and it could be
  handling a lot of requests, it's not intended for production and it was
  not checked for security, I mean, it could expose your filesystem to
  Internet, which is never desirable.
  """
  import Plug.Conn

  @behaviour Plug

  @doc """
  Start the HTTP server using Bandit.
  """
  def start_server(port, dir) do
    IO.puts(["HTTP Server on ", IO.ANSI.yellow(), "http://localhost:#{port}/", IO.ANSI.reset()])
    IO.puts(["Reading from ", IO.ANSI.green(), dir, IO.ANSI.reset()])

    case Bandit.start_link(plug: {__MODULE__, dir}, port: port) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, error} -> throw({:error, error})
    end
  end

  @impl Plug
  def init(dir), do: dir

  @impl Plug
  def call(conn, dir) do
    case find_file(dir, conn.request_path) do
      {:ok, file} ->
        conn
        |> put_resp_content_type(content_type(file))
        |> send_resp(200, File.read!(file))
        |> tap(&log/1)

      :error ->
        conn
        |> send_resp(404, "")
        |> tap(&log/1)
    end
  end

  defp find_file(dir, request_path) do
    file = Path.join([dir, request_path])
    index_file = Path.join(file, "index.html")

    cond do
      File.regular?(file) -> {:ok, file}
      File.regular?(index_file) -> {:ok, index_file}
      true -> :error
    end
  end

  defp content_type(file) do
    file
    |> Path.extname()
    |> String.trim_leading(".")
    |> MIME.type()
  end

  defp log(conn) do
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    IO.puts("#{ip} \"#{conn.method} #{conn.request_path}\" #{conn.status}")
  end
end
