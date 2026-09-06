-module(minimal_blog).

config(_Args) ->
  #{
    blog => {eterm, "blog.config"}
  }.
