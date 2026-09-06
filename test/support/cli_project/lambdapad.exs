import Lambdapad

blog do
  config do
    set(format: :toml)
    set(from: "config.toml")
  end

  pages "index" do
    set(from: "snippets/about.md")
    set(uri: "/index.html")
    set(uri_type: :file)
    set(format: :eex)
    set(template: "index.html.eex")
    set(var_name: "page")
    set(headers: false)
  end
end
