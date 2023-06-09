import Lambdapad

blog do
  config do
    set(format: :eterm)
    set(from: "blog.config")
    set(var_name: "blog")
  end

  extension("test/support/blog_extension.exs")

  assets "files" do
    set(from: "assets/*.css")
    set(to: "site/css")
  end

  source(posts: "posts/**/*.md")

  widget "recent posts" do
    set(from: :posts)
    set(var_name: "posts")
    set(index: true)
    set(template: "recent-posts.html")
    set(format: :eex)

    set(
      env: %{
        site_root: "/"
      }
    )
  end

  pages "about" do
    set(from: "snippets/about.md")
    set(var_name: "about")
    set(template: "index.html")
    set(uri: "/about")
    set(format: :eex)

    set(
      env: %{
        site_root: "/"
      }
    )
  end

  pages "posts" do
    set(from: :posts)
    set(template: "posts.html")
    set(index: true)
    set(var_name: "posts")
    set(uri: "/posts")
    set(format: :eex)

    set(
      env: %{
        site_root: "/"
      }
    )
  end

  pages "individual posts" do
    set(from: :posts)
    set(template: "post.html")
    set(var_name: "post")
    set(uri: "/posts/{{ post.id }}")
    set(format: :eex)

    set(
      env: %{
        site_root: "/"
      }
    )
  end
end
