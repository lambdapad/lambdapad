import Lambdapad

blog do
  config do
    set(format: :eterm)
    set(from: "blog.config")
    set(var_name: "blog")
  end

  pages "sitemap" do
    set(var_name: "sitemap")
    set(template: "sitemap.xml")
    set(uri: "/sitemap.xml")
    set(format: :eex)
  end
end
