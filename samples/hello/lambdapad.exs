import Lambdapad

blog do
  pages "index" do
    set from: "pages/hello.md"
    set template: "index.html"
    set uri: "/"
    set var_name: "page"
  end
end
