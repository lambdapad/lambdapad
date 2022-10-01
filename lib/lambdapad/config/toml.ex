defmodule Lambdapad.Config.Toml do
  @moduledoc """
  TOML configuration backend. This module provides the feature for
  reading the configuration form `config.toml` or other file provided
  by the main script.
  """
  @behaviour Lambdapad.Config

  @impl Lambdapad.Config
  def read_data(file, workdir) do
    Toml.decode_file(Path.join([workdir, file]))
  end
end
