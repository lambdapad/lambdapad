-module(blog).

-define(SITE_ROOT, "/").

config(_Args) ->
  #{
    blog => {eterm, "blog.config"}
  }.

assets(_Config) ->
  #{
    files => {"assets/*.css", "site/css"}
  }.

widgets(_Config) ->
  #{
    "recent posts" => {
      template, "recent-posts.html",
      {posts, "posts/**/*.md"},
      #{
        env => #{
          site_root => ?SITE_ROOT
        }
      }
    }
  }.

pages(_Config) ->
  #{
    "/about" => {
      template_map, "index.html",
      {about, "snippets/about.md"},
      #{
        env => #{
          site_root => ?SITE_ROOT
        }
      }
    },
    "/posts" => {
      template, "posts.html",
      {posts, "posts/**/*.md"},
      #{
        env => #{
          site_root => ?SITE_ROOT
        }
      }
    },
    "/posts/{{ post.id }}" => {
      template_map, "post.html",
      {post, "posts/**/*.md"},
      #{
        env => #{
          site_root => ?SITE_ROOT
        }
      }
    }
  }.
