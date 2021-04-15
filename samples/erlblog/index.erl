-module(index).

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
      template, "index.html",
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
    },
    "/examples" => {
      template, "example.html",
      undefined,
      #{
        env => #{
          site_root => ?SITE_ROOT,
          example_file_content => get_current_file(),
          example_file => "index.erl"
        }
      }
    }
  }.

get_current_file() ->
  escript:script_name(),
  ok.
