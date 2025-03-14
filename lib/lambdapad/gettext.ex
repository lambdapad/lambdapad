defmodule Lambdapad.Gettext do
  @moduledoc """
  Provide a gettext module for the blog. This is helping us to place the
  translations in the right place for the project we are creating.
  """

  @doc """
  Compile the blog configuring the place where the translations will be stored.
  """
  def compile(priv) do
    quoted =
      quote do
        defmodule Lambdapad.Blog.Gettext do
          @moduledoc false
          use Gettext.Backend, otp_app: :lambdapad, priv: unquote(priv)
        end
      end

    Code.compiler_options(ignore_module_conflict: true)
    [{mod, _}] = Code.compile_quoted(quoted)
    {:ok, mod}
  end
end
