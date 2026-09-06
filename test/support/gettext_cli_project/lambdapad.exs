import Lambdapad

blog do
  config do
    set(format: :toml)
    set(from: "config.toml")
  end

  widget "greeting" do
    set(format: :eex)
    set(template: "greeting.html.eex")
    set(var_name: :plain)
  end
end
