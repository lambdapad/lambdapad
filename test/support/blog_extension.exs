doc("""
Last Update Extension
0.1

During the configuration stage it's reading all of the posts
and getting the date most recent. This set into the config
the value for `last_update`. This is meaning you can use into
your templates:

Blog last updated: {{last_updated}}

The date is retrieved from the post header, so you have to
define:

date: 2021-08-27

We consider this the creation date. If you update the post, it's
better to use:

date: 2021-08-27
updated: 2021-09-29

And change only the last one. This extension is going to search for
the second one and if it's not found then the first one.

To use the transform, you have to add it:

  pages "atom_xml" do
    set from: :posts
    set uri: "/atom.xml"
    set uri_type: :file
    set index: true
    set template: "atom.xml"
    set transform_on_item: ["date", "tags", "author"]
    set transform_on_page: ["atom_elements"]
    set transform_on_config: ["last_update"]
    set var_name: "posts"
  end

As you can see, it's in the `transform_on_config` setting.

Enjoy!
""")

transform "last_update" do
  set(on: :config)

  set(
    run: fn config, posts ->
      last_update =
        posts
        |> Enum.map(&(&1["updated"] || &1["date"]))
        |> Enum.sort(:desc)
        |> List.first()

      Map.put(config, "last_update", last_update)
    end
  )
end
