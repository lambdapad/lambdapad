import Lambdapad

blog do
  extension("extensions/postinfo.exs")

  config do
    set(
      transform: fn config ->
        config
        |> Map.put("site_root", "/")
        |> Map.put("current_year", Date.utc_today().year)
      end
    )
  end

  source(posts: "posts/**/*.md")
  source(pages: "pages/**/*.md")
  source(docs: "docs/**/*.md")

  # pages "posts" do
  #   set from: :posts
  #   set uri: "/{{ post._date.year }}/{{ post._date.month }}/{{ post._date.day }}/{{ post.id }}"
  #   set var_name: "post"
  #   set template: "post.html"
  #   set transform_on_item: ["date"]
  # end

  assets "general" do
    set(from: "assets/{favicons,images,webfonts}/**")
    set(to: "site/")
  end

  assets "node_modules" do
    set(from: "package.json")
    set(tool: :npm)
    set(priority: :high)
  end

  assets "js" do
    set(from: "assets/**/*.js")
    set(to: "site/")
    set(tool: :esbuild)
    set(esbuild: [
      target: "es2017"
    ])
  end

  assets "css" do
    set(from: "assets/**/*.css")
    set(to: "site/")
    set(tool: :tailwind)
  end

  # copy `lpad` binary to the download space
  assets "lpad" do
    set(from: "lpad")
    set(to: "site/download/lpad")
  end

  pages "index" do
    set(template: "index.html")
    set(uri: "/")
  end

  # Documentation

  # Table of Contents
  widget "toc" do
    set(from: :docs)
    set(var_name: "pages")
    set(index: true)
    set(excerpt: false)
    set(headers: true)
    set(template: "toc.html")
  end

  pages "docs" do
    set(from: :docs)

    set(
      uri: fn _idx, config ->
        {"page", page} = List.keyfind(config, "page", 0)

        case List.keyfind(page, "id", 0) do
          {"id", "index"} -> "/docs"
          {"id", page_id} -> "/docs/#{page_id}"
        end
      end
    )

    set(var_name: "page")
    set(excerpt: false)
    set(headers: true)
    set(template: "doc.html")
  end

  # Other pages (i.e. About)
  pages "pages" do
    set(from: :pages)
    set(uri: "/{{ page.id }}")
    set(var_name: "page")
    set(excerpt: false)
    set(headers: false)
    set(template: "page.html")
    set(transform_on_item: ["ensure date"])
  end
end
