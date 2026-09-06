import Lambdapad

blog do
  config do
    set(format: :eterm)
    set(from: "blog.config")
    set(var_name: "blog")
  end

  pages "broken" do
    set(from: :missing_source)
    set(var_name: "broken")
    set(template: "index.html")
    set(uri: "/broken")
    set(format: :eex)

    set_env(site_root: "/")
  end
end
