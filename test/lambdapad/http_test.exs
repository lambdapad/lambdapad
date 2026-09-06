defmodule Lambdapad.HttpTest do
  use ExUnit.Case
  alias Lambdapad.Http

  setup_all do
    dir =
      Path.join(System.tmp_dir!(), "lambdapad_http_test_#{System.unique_integer([:positive])}")

    File.mkdir_p!(dir)
    File.write!(Path.join(dir, "hello.txt"), "hello world")
    File.mkdir_p!(Path.join(dir, "sub"))
    File.write!(Path.join([dir, "sub", "index.html"]), "<h1>sub index</h1>")

    port = 8000 + rem(System.unique_integer([:positive]), 1000)
    :ok = Http.start_server(port, dir)

    {:ok, port: port}
  end

  defp get(port, path) do
    url = String.to_charlist("http://127.0.0.1:#{port}#{path}")

    {:ok, {{_, status, _}, headers, body}} =
      :httpc.request(:get, {url, []}, [], body_format: :binary)

    {status, headers, body}
  end

  test "serves an existing file with its content type", %{port: port} do
    {status, headers, body} = get(port, "/hello.txt")

    assert status == 200
    assert body == "hello world"
    assert {~c"content-type", content_type} = List.keyfind(headers, ~c"content-type", 0)
    assert List.starts_with?(content_type, ~c"text/plain")
  end

  test "falls back to index.html when the path is a directory", %{port: port} do
    {status, _headers, body} = get(port, "/sub/")

    assert status == 200
    assert body == "<h1>sub index</h1>"
  end

  test "returns 404 when nothing matches", %{port: port} do
    {status, _headers, _body} = get(port, "/does-not-exist.txt")

    assert status == 404
  end
end
