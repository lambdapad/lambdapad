id: elixir-configuration
date: 2022-05-16
updated: 2022-10-14
title: Elixir Configuration
group: Core Concepts

[TOML]: https://github.com/toml-lang/toml
[EEx]: https://hexdocs.pm/eex/EEx.html

Everything is defined into two different files. The first one is the script in use to define what's going to take place (`lambdapad.exs`) and the other file is the configuration to get easier change parameters (`config.toml`). Both are necessary into your directory. The usual content for `config.toml` is as follows:

```toml
[blog]
url = "http://localhost:8080"
title = "My Blog"
description = "I put my ideas here... what else?"
```

Actually, you can include more sections inside of this file which are going to be accessible from the templates and the transformations.

You can add as many deep levels as you need, but we recommend to keep it as simple as possible.

You'll need also define information inside of `lambdapad.exs` to know what to generate:

```elixir
import Lambdapad

blog do
  source posts: "posts/**.md"

  pages "posts index" do
    set from: :posts
    set index: true
    set uri: "/"
    set template: "posts.html"
    set var_name: "posts"
  end

  pages "posts" do
    set from: :posts
    set uri: "/{{ post.id }}"
    set template: "post.html"
    set var_name: "post"
  end
end
```

Neat! More or less. There is a lot to comment, but first, there is a convention into the creation of the directories:

- `posts`: where we put explicitly posts when we are to create a blog.
- `pages`: where we put the extra pages, like about or the normal pages a website should have.
- `templates`: where we put the templates (usually ErlyDTL at the moment).
- `assets`: where all of the static files should be placed. Be careful if you are using something like webpack, brunch or similar. This should be the destination directory for these tools and not the directory containing all of the generator and node modules directory.

In the same way the default file for the site it's usually `lambdapad.exs` and the configuration (if we are not indicating anything) it's `config.toml`.

## Configuration Blocks

We defined different blocks to be analysed and in use by lambdapad to generate the website. We are going to see them in detail right now.

### `config`

The `config` block is only needed if we want to change the provider (one instead of [TOML][TOML]), the name of the configuration file or we want to perform a change into the configuration. The sets we can configure are the following:

- `from` (string) set the name of the configuration file, by default it's `config.toml`.
- `format` (atom) set the type of the configuration file. At this moment we can only use `:toml`.
- `transform` (function) let us set a function to change the configuration. It is only running once when we retrieve the configuration from the file and we can only define one function:

```elixir
config do
  set transform: fn(config) ->
    Map.put(config, "site_root", config["blog"]["url"])
  end
end
```

### `source`

This special tag is very simple and is only defining aliases for specific paths:

```elixir
source posts: "posts/**/*.md"
source pages: "pages/**/*.md"
```

This way in every `from` set for `pages` or `widget` we can use `:posts` or `:pages` instead of write the wildcard paths again and again.

### `assets`

This block help us to copy the static files into the destination target. This is the most simple one because only accepts two configurations:

- `from` (string) letting set the wildcard from where we are going to get the files.
- `to` (string) setting the directory where these files are going to be placed.

If we set `assets/**` this is meaning the whole tree directory under `assets` is going to be copied to the destionation directory. We can configure as many `assets` blocks as we need:

```elixir
assets "js" do
  set from: "js/dist/*.js"
  set to: "site/js/"
end

assets "css" do
  set from: "css/dist/*.css"
  set to: "site/css/"
end
```
### `transform`

The transform is the definition of a functional action to be performed to a set of pages or for each page each time, or even to the configuration.

The sets we can use to define a transform are:

- `on` (:config | :page | :item) specifies where the transform will be working. If we are defining an action only to work with individual items, of course, it couldn't be applied for the whole set of pages or for configuration. We'll check what are the differences.
- `run` (function) the function to be called. Depending on the previous value, it could be:
  - `:config`: a function receiving config as first parameter and pages as second one, it should return the modified config. It's configured in `transform_on_config` for `widget` and `pages` block.

  ```elixir
  transform "last_updated" do
    set on: :config
    set run: fn(config, pages) ->
      last_updated =
        pages
        |> Enum.map(& &1["updated"] || &1["date"])
        |> Enum.sort(:desc)
        |> List.first()

      Map.put(config, "last_updated", last_updated)
    end
  end
  ```

  The transformation is getting the most recent date from the posts priorizing the existence of the updated over date. Of course, we have to provide one or another inside of the page header.

  - `:page`: a function receiving pages as first parameter and config as second one, it should return the modified pages. It's configured in `transform_on_page` for `widget` and `pages` blocks.

  ```elixir
  transform "order by date desc" do
    set on: :page
    set run: fn(pages, config) ->
      Enum.sort_by(pages, & &1["date"], :desc)
    end
  end
  ```

  The transformation is ordering the pages based on the `date` information from its header in a desc order.

  - `:item`: a function receiving page as first parameter and config as second one, it should return the modified page. It's configured in `transform_on_item` for `widget` and `pages` blocks.

  ```elixir
  transform "date" do
    set on: :item
    set run: fn(post, config) ->
      %{day: day, month: month, year: year} = Date.from_iso8601!(post["date"])
      Map.put(post, "_date", %{
        day: String.pad_leading(to_string(day), 2, "0"),
        month: String.pad_leading(to_string(month), 2, "0"),
        year: to_string(year)
      })
    end
  end
  ```

  - `:persist`: a function receiving data as first parameter and page data as second parameter, it should return the modification of the data. This data will be inserted into `:url_data` property list using the URL as key. It's a way to get the list of the generated pages at some specific point (i.e. it's useful for the definition of a `pages` block to create a `sitemap.xml`):

  ```elixir
  transform "sitemap" do
    set on: :persist
    set run: fn(data, _page) ->
      date = Date.utc_today() |> to_string()
      Map.merge(data, %{"last_updated", date})
    end
  end
  ```

  The transformation is modifying each post providing a new key `_date` which is containing the keys `day`, `month` and `year`.

As you can see every transformation requieres a different function defined. It's accepting different parameters and returning different results.

**Note** that `:page` let us even change the way the posts are stored. This is very useful if we want to create a hierachical store to present the pages based on one specific tag (i.e. category, tags or year)

### `widget`

This is the more powerful block because let us process parts of a page and then we can embedded them into others. For this we have different elements, first we can define as many widget blocks as we need:

```elixir
widget "recent posts" do
  set from: :posts
  set template: "recent-posts.html"
  set transform_on_page: fn(posts, config) ->
    Enum.take(posts, config["blog"]["num_of_recent_posts"])
  end
  set var_name: "posts"
end
```

The sets we can use for widgets are the following:

- `from` (string | atom) is telling where to find the files to be processed. We could use a definition from `source`.
- `template` (string) the name of the template file in use for rendering the widget.
- `transform_on_page` (function | string | list(function | string)) a lambda with two arguments saying what transformation we want to perform on the set of pages. We can use `transform` block to define a tranformation and use only the name here. We can add as many transformations as we need. See `transform` section for further information.
- `transform_on_item` (function | string | list(function | strings)) a lambda with two arguments saying what transformation we want to perform on a single page each time. This is running once per item into the set of pages retrieved using `from`. We can add as many transformations as we need. See `transform` section for further information.
- `headers` (boolean) is telling if the markdown files have headers or not. Default value is `true`.
- `excerpt` (boolean) is telling if the markdown files have excerpt or not. If we configure this value to `true` and the `<!--more-->` mark is present, the text before it is used as the excerpt; otherwise the excerpt falls back to the first line of the content (not the first paragraph, so a soft-wrapped paragraph would be cut short). Default value is `true`.
- `var_name` (string | :plain) it's setting the list of pages using the name provided here to be in use into the template. The default value is `:plain`.
- `format` (:erlydtl) yes, it makes no sense to put this value at the moment, but in near future it's desirable to have also support for other template engines like `:eex`. [Keep in touch!][EEx].
- `env` (map) it's letting us to define extra parameters for the template in a map format (see pages example for further information).

**Note** that if the `from` is retrieving different files, it will generate a list of elements which cannot be merge with the list of values, therefore `:plain` will be changed automatically to `"pages"` giving a warning.

The generation of the widgets is inserted into the configuration under the key `widgets`. But it's even easier to use, when we are into the template we have only to use:

```django
{% widget "recent posts" %}
```

And then the widget is put in that place.

The flow it follows is:

1. The information for pages is retrieved (using `from`). But `from` isn't required so, it's possible to render only the template. Actually this makes no sense because it's better use `include` in this case.
2. The pages are processed item by item (using `transforms_on_item`). If there are no pages from step 1 or the transformations are not defined this step is ommited.
3. The pages are processed as a whole (using `transform_on_page`). If there are no pages from step 1 or the transformations are not defined this step is ommited.
4. The page is rendered using the template.
5. Information is stored into the configuration to be in use into the pages.

### `pages`

This is the important block. This block is in charge of generating the pages into the destination directory. As we read previously this is helped of `source` block to define wildcard paths as atoms and `transform` to define transformations using names.

The sets we can use with `pages` are the following:

- `from` (string | atom) is telling where to find the files to be processed. We could use a definition from `source`.
- `uri` (string | function) the URI used to access to the page. We can use here a string formatted in `erlydtl` way:

  ```elixir
  set uri: "/{{ page.id }}"
  ```

  or using a function where we are going to receive the `index` and generate different pages based on this index. Very useful for pagination:

  ```elixir
  set uri: fn
    (1) -> "/"
    (index) -> "/page/#{index}"
  end
  ```

- `uri_type` (`:dir` | `:file`) the `uri` is always being created as a directory and inside a `index.html` file, but if we want to create specifically another file, i.e. `atom.xml`, we could specify the `uri` including the file and then setting `uri_type` as `:file`. Default value  is `:dir`.
- `index` (boolean) we say if we are going to process all of the posts in only one template or one post per template. This is helping to create pages like indexes of posts or all of the post pages one by one.
- `paginated` (false | integer | function) we are indicating if we are going to paginate a page defined as index (`set index: true`) we can set this value as `false` (the default value), the number of elements per page (positive integer):

  ```elixir
  set paginated: 12
  ```

  or a function which is returning the number of elements per page (positive integer) receiving the config as parameter:

  ```elixir
  set paginated: fn(config) ->
    config["blog"]["max_items_per_page"]
  end
  ```

- `template` (string) the name of the template file in use for rendering the widget.
- `transform_on_config` (function | string | list(function | string)) a lambda with two arguments saying what transformation we want to perform on the set of pages. We can use `transform` block to define a tranformation and use only the name here. We can add as many transformations as we need. See `transform` section for further information.
- `transform_on_page` (function | string | list(function | string)) a lambda with two arguments saying what transformation we want to perform on the set of pages. We can use `transform` block to define a tranformation and use only the name here. We can add as many transformations as we need. See `transform` section for further information.
- `transform_on_item` (function | string | list(function | string)) a lambda with two arguments saying what transformation we want to perform on a single page each time. This is running once per item into the set of pages retrieved using `from`. We can add as many transformations as we need. See `transform` section for further information.
- `transform_to_persist` (function | string | list(function | string)) a lambda with two arguments saying what information should be persisted for the URL generated. The information will be retrieved for the following pages into the *config* under `url_data` using the URL as key and the persisted data as value.
- `headers` (boolean) is telling if the markdown files have headers or not. Default value is `true`.
- `excerpt` (boolean) is telling if the markdown files have excerpt or not. If we configure this value to `true` and the `<!--more-->` mark is present, the text before it is used as the excerpt; otherwise the excerpt falls back to the first line of the content (not the first paragraph, so a soft-wrapped paragraph would be cut short). Default value is `true`.
- `var_name` (string | `:plain`) it's setting the list of pages using the name provided here to be in use into the template. The default value is `"page"`.
- `format` (`:erlydtl`) yes, it makes no sense to put this value at the moment, but in near future it's desirable to have also support for other template engines like `:eex`. [Keep in touch!][EEx].
- `env` (map) it's letting us to define extra parameters for the template in a map format:

  ```elixir
  set env: %{
    "environment" => System.get_env("LPAD_ENV") || "dev"
  }
  ```

- `priority` (`:high` | `:low` | `0..100`) indicates when the page will be generated: pages are sorted by priority and generated in that order, and a lower number means a higher priority (it's generated earlier). `:high` is equivalent to `0` and `:low` is equivalent to `100`; if you don't set it, it defaults to `50`. It's useful when we want to use `transform_to_persist` and generate `sitemaps` at the end of the generation of the blog, for example by giving the sitemap page a `:low` priority.

The way the pages are rendered into the files depends on the configuration. But mainly they follow these steps:

1. The pages are retrieved (read) from the place we have configure (`from`). But even it's possible avoid this and only render a template without specific content. This step is optional.
2. The pages are processed item by item (using `transforms_on_item`). If there are no pages from step 1 this step is ommited.
3. The pages are processed as a whole (using `transform_on_page`). If there are no pages from step 1 this step is ommited.
4. The config is processed based on the pages (using `transform_on_config`). If there are no pages from step 1 this step is ommited.
5. The page is rendered using the template and appliying the widgets.
6. File is written using the render page.
7. The page data is processed by the `transform_to_persist` function and modify the configuration for the specific URL. If the `pages` generates several files, then several URLs are going to be saved into the `url_data` configuration.

### checks

When we have to check if our website was correctly built we could inject some specific code which could help us to determine if that was right or not. A typical check we can perform is for broken links:

```elixir
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
```

`:links` and `:url_data` are provided by Lambdapad. `:url_data` could be modified (its content) by `transform_to_persist` transformations (into every `page` block).

The only option available at this moment for `on` is `:finish`. The `run` option only accepts a valid _closure_ (or anonymous function) which admits one parameter.

You can perform whatever inside of the check and it's a good idea to return the config again because if you are using more than one check, it's going to run the following one based on the config you returned.
