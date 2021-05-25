import Lambdapad

blog do
  config do
    set transform: fn(config) ->
      Map.put(config, "site_root", config["blog"]["url"])
    end
  end

  check "broken local links" do
    set on: :finish
    set run: fn(config) ->
      urls = for {url, _} <- config[:url_data], do: URI.parse(url)
      site_root = config["site_root"]
      for link <- config[:links] do
        if String.starts_with?(link, site_root) do
          link =
            if String.ends_with?(link, "index.html") do
              String.replace_suffix(link, "/index.html", "")
            else
              link
            end

          unless URI.parse(link) in urls do
            raise """
            Broken link: #{link}
            """
          end
        end
      end
      config
    end
  end

  assets "css" do
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

  transform "sitemap" do
    set on: :persist
    set run: fn(data, page) ->
      page = Map.new(page)
      Map.put(data, "last_update", page["updated"] || page["date"])
    end
  end

  pages "sitemap" do
    set template: "sitemap.xml"
    set uri: "/sitemap.xml"
    set uri_type: :file
    set priority: :low
  end

  pages "index" do
    set from: "snippets/about.md"
    set template: "index.html"
    set uri: "/"
    set var_name: "about"
    set transform_to_persist: fn(data, page) ->
      page =
        page
        |> Map.new()
        |> Access.get("about")
        |> Map.new()

      Map.merge(data, %{"last_update" => page["date"]})
    end
  end

  pages "posts index" do
    set from: :posts
    set template: "posts.html"
    set uri: "/posts"
    set index: true
    set var_name: "posts"
    set transform_to_persist: fn(data, page) ->
      date =
        page
        |> Map.new()
        |> Access.get("posts")
        |> Enum.map(fn post ->
          post = Map.new(post)
          post["date"]
        end)
        |> Enum.sort(:desc)
        |> List.first()

      Map.merge(data, %{"last_update" => date})
    end
  end

  pages "posts" do
    set from: :posts
    set template: "post.html"
    set uri: "/posts/{{post.id}}"
    set var_name: "post"
    set transform_to_persist: fn(data, page) ->
      post =
        page
        |> Map.new()
        |> Access.get("post")
        |> Map.new()

      Map.merge(data, %{"last_update" => post["date"]})
    end
  end

  pages "examples" do
    set template: "example.html"
    set uri: "/examples"
    set env: %{
      "example_file_content" => File.read!(Path.join([__DIR__, "lambdapad.exs"])),
      "example_file" => "lambdapad.exs"
    }
    set transform_to_persist: fn(data, _page) ->
      date = Date.utc_today() |> to_string()
      Map.merge(data, %{"last_update" => date})
    end
  end
end
