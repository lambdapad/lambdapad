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

pages(Config) ->
  Blog = get_value("blog", Config),
  Workdir = get_value("workdir", Blog),
  #{
    "/" => {
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
          example_file_content => get_current_file(Workdir),
          example_file => "index.erl"
        }
      }
    }
  }.

get_value(String, Config) when is_list(String) ->
  get_value(list_to_binary(String), Config);
get_value(Binary, Config) ->
  maps:get(Binary, Config).

get_current_file(Workdir) ->
  Filename = iolist_to_binary([Workdir, "/index.erl"]),
  {ok, Content} = file:read_file(Filename),
  Content.
