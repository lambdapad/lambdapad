@doc """
The author transformation is applied on every item/post/page.
It requires to have defined the metadata `author` and it's
providing a `_author` entry populating it from the configuration.

For getting this working properly you need to add to the
configuration file an `authors` entry, where we can find
the name of the author and inside the data, i.e.

```toml
# config.toml
[authors]

[authors.manuel]
shortname = "manuel"
name = "Manuel Rubio"
url = "curriculum-vitae/manuel"
email = "manuel@altenwald.com"
description = "Programación Concurrente & Erlanger"
```

This way, if you add to the post or page the metadata `manuel` it will
add to the post data the `_author` data with information like `email`,
`description`, and `name`.
"""
transform "author" do
  set(on: :item)

  set(
    run: fn post, config ->
      author = post["author"]
      author_data = config["authors"][author] || %{}
      Map.put(post, "_author", author_data)
    end
  )
end

@doc """
The date transformation is applied for each item/post/page and it will
get the existing date from the metadata and create the `_date` entry
with the information of `day`, `month`, and `year`.

It's useful for URIs and templates where we want to get the information
about the date of the entries split in day, month, and year.
"""
transform "date" do
  set(on: :item)

  set(
    run: fn post, _config ->
      %{day: day, month: month, year: year} = Date.from_iso8601!(post["date"])

      Map.put(post, "_date", %{
        day: String.pad_leading(to_string(day), 2, "0"),
        month: String.pad_leading(to_string(month), 2, "0"),
        year: to_string(year)
      })
    end
  )
end

@doc """
Similar to `date` but in case the `date` entry isn't found in the metadata
it's using the current date and setting properly `date` and `_date`.
"""
transform "ensure date" do
  set(on: :item)

  set(
    run: fn page, _config ->
      if page_date = page["date"] do
        %_{year: year, month: month, day: day} = Date.from_iso8601!(page_date)
        Map.put(page, "_date", %{year: year, month: month, day: day})
      else
        today = Date.utc_today()

        page
        |> Map.put("date", to_string(today))
        |> Map.put("_date", today)
      end
    end
  )
end

@doc """
Group by year. This transformation is applied to the set of pages/posts. It
requires to have applied for each item the `date` or `ensure date`
transformations.

It's changing the `posts` or `pages` entry for grouping under the `year` all
of the pages.
"""
transform "group by year" do
  set(on: :page)

  set(
    run: fn posts, _config ->
      Enum.reduce(posts, %{}, fn %{"_date" => %{year: year}} = post, acc ->
        Map.update(acc, year, [post], &(&1 ++ [post]))
      end)
      |> Enum.reverse()
    end
  )
end

@doc """
Applied on pages/posts the order by date (desc) is ensuring the pages/posts
are ordered following that criteria. It's recommended to have `ensure date`
transformation for each item for ensuring all of the posts/pages have the
date entry.
"""
transform "order by date desc" do
  set(on: :page)

  set(
    run: fn posts, _config ->
      Enum.sort_by(posts, & &1["date"], :desc)
    end
  )
end
