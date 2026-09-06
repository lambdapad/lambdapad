import Lambdapad

blog do
  config do
    set(format: :toml)
    set(from: "config.toml")
  end

  pages "third" do
    set(from: "a.md")
    set(uri: "/third.html")
    set(uri_type: :file)
    set(format: :eex)
    set(template: "t.html.eex")
    set(var_name: "page")
    set(priority: :low)
  end

  pages "first" do
    set(from: "a.md")
    set(uri: "/first.html")
    set(uri_type: :file)
    set(format: :eex)
    set(template: "t.html.eex")
    set(var_name: "page")
    set(priority: :high)
  end

  pages "second" do
    set(from: "a.md")
    set(uri: "/second.html")
    set(uri_type: :file)
    set(format: :eex)
    set(template: "t.html.eex")
    set(var_name: "page")
    set(priority: 50)
  end

  pages "invalid_priority" do
    set(from: "a.md")
    set(uri: "/invalid.html")
    set(uri_type: :file)
    set(format: :eex)
    set(template: "t.html.eex")
    set(var_name: "page")
    set(priority: "urgent")
  end
end
