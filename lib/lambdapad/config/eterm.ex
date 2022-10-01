defmodule Lambdapad.Config.Eterm do
  @moduledoc """
  Eterm configuration is a way to provide the configuration to the system
  using the Erlang terms. Similar to the way the `sys.config` is written.
  """
  @behaviour Lambdapad.Config

  @impl Lambdapad.Config
  def read_data(file, workdir) do
    :file.script(Path.join([workdir, file]))
  end
end
