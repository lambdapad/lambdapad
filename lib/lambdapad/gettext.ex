defmodule Lambdapad.Gettext do
  def compile(priv) do
    quoted = quote do
      defmodule Lambdapad.Blog.Gettext do
        use Gettext, otp_app: :lambdapad, priv: unquote(priv)
      end
    end
    Code.compiler_options(ignore_module_conflict: true)
    [{mod, _}] = Code.compile_quoted(quoted)
    {:ok, mod}
  end
end
