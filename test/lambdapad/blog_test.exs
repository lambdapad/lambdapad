defmodule Lambdapad.BlogTest do
  use ExUnit.Case

  alias Lambdapad.Blog

  test "blog.erl" do
    file = Path.join([__DIR__, "../support/blog.erl"])
    assert {:ok, mod} = Blog.Erl.compile(file)

    config = Blog.Base.get_configs(mod, [])
    assert [%{format: :eterm, from: "blog.config", var_name: "blog"}] == config

    assert %{
             "recent posts" => %{
               env: %{site_root: '/'},
               excerpt: true,
               format: :erlydtl,
               from: "posts/**/*.md",
               headers: true,
               index: true,
               template: "recent-posts.html",
               var_name: "posts"
             }
           } == Blog.Base.get_widgets(mod, config)

    assert %{
             "/about" => %{
               env: %{site_root: '/'},
               excerpt: true,
               format: :erlydtl,
               from: "snippets/about.md",
               headers: true,
               index: false,
               paginated: false,
               template: "index.html",
               uri: "/about",
               uri_type: :dir,
               var_name: "about"
             },
             "/posts" => %{
               env: %{site_root: '/'},
               excerpt: true,
               format: :erlydtl,
               from: "posts/**/*.md",
               headers: true,
               index: true,
               paginated: false,
               template: "posts.html",
               uri: "/posts",
               uri_type: :dir,
               var_name: "posts"
             },
             "/posts/{{ post.id }}" => %{
               env: %{site_root: '/'},
               excerpt: true,
               format: :erlydtl,
               from: "posts/**/*.md",
               headers: true,
               index: false,
               paginated: false,
               template: "post.html",
               uri: "/posts/{{ post.id }}",
               uri_type: :dir,
               var_name: "post"
             }
           } == Map.new(Blog.Base.get_pages(mod, config))

    assert %{
             "files" => %{
               from: "assets/*.css",
               to: "site/css"
             }
           } == Blog.Base.get_assets(mod, config)
  end

  test "blog.exs" do
    file = Path.join([__DIR__, "../support/blog.exs"])
    assert {:ok, mod} = Blog.Exs.compile(file)

    config = Blog.Base.get_configs(mod, [])

    assert [
             %{
               format: :eterm,
               from: "blog.config",
               var_name: "blog",
               transform_from_pages: nil
             }
           ] == config

    assert %{
             "recent posts" => %{
               env: %{site_root: "/"},
               excerpt: true,
               format: :eex,
               from: "posts/**/*.md",
               headers: true,
               index: true,
               template: "recent-posts.html",
               var_name: "posts"
             }
           } == Blog.Base.get_widgets(mod, config)

    assert %{
             "about" => %{
               env: %{site_root: "/"},
               excerpt: true,
               format: :eex,
               from: "snippets/about.md",
               headers: true,
               index: false,
               paginated: false,
               template: "index.html",
               uri: "/about",
               uri_type: :dir,
               var_name: "about"
             },
             "posts" => %{
               env: %{site_root: "/"},
               excerpt: true,
               format: :eex,
               from: "posts/**/*.md",
               headers: true,
               index: true,
               paginated: false,
               template: "posts.html",
               uri: "/posts",
               uri_type: :dir,
               var_name: "posts"
             },
             "individual posts" => %{
               env: %{site_root: "/"},
               excerpt: true,
               format: :eex,
               from: "posts/**/*.md",
               headers: true,
               index: false,
               paginated: false,
               template: "post.html",
               uri: "/posts/{{ post.id }}",
               uri_type: :dir,
               var_name: "post"
             }
           } == Map.new(Blog.Base.get_pages(mod, config))

    assert %{
             "files" => %{
               from: "assets/*.css",
               to: "site/css"
             }
           } == Blog.Base.get_assets(mod, config)
  end

  test "blog_extended.exs" do
    file = Path.join([__DIR__, "../support/blog_extended.exs"])
    assert {:ok, mod} = Blog.Exs.compile(file)

    config = Blog.Base.get_configs(mod, [])

    assert [
             %{
               format: :eterm,
               from: "blog.config",
               var_name: "blog",
               transform_from_pages: nil
             }
           ] == config

    assert %{
             "recent posts" => %{
               env: %{site_root: "/"},
               excerpt: true,
               format: :eex,
               from: "posts/**/*.md",
               headers: true,
               index: true,
               template: "recent-posts.html",
               var_name: "posts"
             }
           } == Blog.Base.get_widgets(mod, config)

    assert %{
             "about" => %{
               env: %{site_root: "/"},
               excerpt: true,
               format: :eex,
               from: "snippets/about.md",
               headers: true,
               index: false,
               paginated: false,
               template: "index.html",
               uri: "/about",
               uri_type: :dir,
               var_name: "about"
             },
             "posts" => %{
               env: %{site_root: "/"},
               excerpt: true,
               format: :eex,
               from: "posts/**/*.md",
               headers: true,
               index: true,
               paginated: false,
               template: "posts.html",
               uri: "/posts",
               uri_type: :dir,
               var_name: "posts"
             },
             "individual posts" => %{
               env: %{site_root: "/"},
               excerpt: true,
               format: :eex,
               from: "posts/**/*.md",
               headers: true,
               index: false,
               paginated: false,
               template: "post.html",
               uri: "/posts/{{ post.id }}",
               uri_type: :dir,
               var_name: "post"
             }
           } == Map.new(Blog.Base.get_pages(mod, config))

    assert %{"last_update" => %{on: :config, run: _}} = Lambdapad.Blog.transforms()

    assert %{
             "files" => %{
               from: "assets/*.css",
               to: "site/css"
             }
           } == Blog.Base.get_assets(mod, config)
  end
end
