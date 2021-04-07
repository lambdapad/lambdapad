import Lambdapad

blog do
  config do
    set transform: fn(config) ->
      Map.put(config, "site_root", config["blog"]["url"])
    end
  end

  assets do
    set from: "assets/*.css"
    set to: "site/css"
  end

  source posts: "posts/*.md"

  widget "recent posts" do
    set from: :posts
    set index: true
    set template: "recent-posts.html"
    set var_name: "posts"
  end

  pages "index" do
    set from: "snippets/about.md"
    set template: "index.html"
    set uri: "/"
    set var_name: "about"
  end

  pages "posts index" do
    set from: :posts
    set template: "posts.html"
    set uri: "/posts"
    set index: true
    set var_name: "posts"
  end

  pages "posts" do
    set from: :posts
    set template: "post.html"
    set uri: "/posts/{{post.id}}"
    set var_name: "post"
  end

  pages "examples" do
    set template: "example.html"
    set uri: "/examples"
    set env: %{
      "example_file_content" => File.read!(Path.join([__DIR__, "lambdapad.exs"])),
      "example_file" => "lambdapad.exs"
    }
  end
end
