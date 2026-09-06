import Lambdapad

blog do
  config do
    set(format: :toml)
    set(from: "config.toml")
  end

  extension("greeting_extension.exs")
end
