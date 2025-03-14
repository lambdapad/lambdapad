defmodule Lambdapad.Html do
  @moduledoc """
  Creates the module necessary for the rendering of the pages given a
  specific name.

  The idea is that providing the information regarding the HTML file,
  the workdir, the backend (i.e. erlydtl), and the name, we can create
  a module which we could use for rendering all of the pages which are
  under the same name.
  """

  @type name() :: String.t()
  @type html_file() :: String.t()
  @type workdir() :: String.t()
  @type backend() :: module()
  @type render_type() :: :page | :widget

  @doc """
  Init must create a new module and return the name of the module.
  This module will be in use by the `render/3` function (as its 2nd
  parameter) and it will generate the pages requested based on the
  data.
  """
  @callback init(render_type(), name(), html_file(), workdir()) :: module()

  @doc """
  The init function is in charge for calling the implementation based
  on the 4th parameter for this behaviour.
  """
  def init(type, name, html_file, workdir, backend) when is_binary(name) do
    Logger.put_module_level(Earmark.Parser.LineScanner, :error)
    backend = Module.concat([__MODULE__, Macro.camelize(to_string(backend))])
    backend.init(type, name, html_file, workdir)
  end

  @doc """
  Given the variables (environment) for the templates, the module
  where we compiled the templates, and the configuration, the
  function is in charge of the rendering for the specific page.
  """
  def render(vars, module, config) do
    vars = vars ++ config
    {:ok, data} = module.render(vars, config)
    IO.iodata_to_binary(data)
  end
end
