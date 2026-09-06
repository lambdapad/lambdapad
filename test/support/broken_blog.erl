-module(broken_blog).

config(_Args) ->
  #{
    blog => {eterm, "blog.config"}
  this_is_a_syntax_error.
