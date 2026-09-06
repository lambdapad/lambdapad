id: extensions
date: 2022-05-16
title: Extensions
group: Advanced

Taking advantage of the Elixir syntax we can add extensions. These extensions are mainly transformations which could be shared and plugged into our projects which make easier to configure different blogs sharing the same extensions. The extensions have to be as isolated files into the system putting only what we need to be plugged and then, inside of the configuration we could use:

```elixir
extension "last_update.exs"
```

This help us to define the content of the file `last_update.exs` as:

```elixir
transform "last_update" do
  set on: :config
  set run: fn(config, posts) ->
    last_update =
      posts
      |> Enum.map(& &1["updated"] || &1["date"])
      |> Enum.sort(:desc)
      |> List.first()

    Map.put(config, "last_update", last_update)
  end
end
```
