# Lambdapad

![lambdapad](lambdapad.png)

Static website generator using Elixir or Erlang. Yes! you can use (syntactic) *sugar* to make *swetter* your experience or Erlang to power the functional way to build your pages!

If you love this content and want we can generate more, you can support us:

[![paypal](https://www.paypalobjects.com/en_US/GB/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=RC5F8STDA6AXE)

<!-- toc -->

## Getting Started

You need only to get the code, from source code you can:

```
git clone https://github.com/altenwald/lambdapad
cd lambdapad
mix deps.get
mix escript.build
```

Then you will have the `lpad` script ready. You can copy it to a place accesible from wherever you are or even include it into the directory you have for generate your blog or website.

When you are running `lpad`, this command searches for a `lambdapad.exs` file into the current directory. You can indicate where the file is located, even if you called it in another way:

```
lpad www/myblog/lambdapad.exs
```

Or if you are going to use the Erlang way:

```
lpad www/myblog/index.erl
```

## Configuration

Everything is defined into two different files. The first one is the script in use to define what's going to take place (i.e. `lambdapad.exs` or `index.erl`) and the other file is the configuration to get easier change parameters (i.e. `config.toml` or `blog.config`). Both are necessary into your directory. The usual content for `config.toml` is as follows:

```toml
[blog]
url = "http://localhost:8080"
title = "My Blog"
description = "I put my ideas here... what else?"
```

Actually, you can include more sections inside of this file which are going to be accesible from the templates and the transformations.

If we want to use `eterm` then we could write it in this way:

```erlang
#{
  url => "http://localhost:8080",
  title => "My Blog",
  description => "I put my ideas here... what else?"
}
```

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

Or using the Erlang format we can write the `index.erl` as follows:

```erlang
-module(index).

config(_Args) ->
  #{
    blog => {eterm, "blog.config"}
  }.

pages(_Config) ->
  #{
    "/" => {
      template_map, "posts.html",
      {posts, "posts/**/*.md"},
      #{}
    },
    "/{{ post.id }}" => {
      template, "post.html",
      {post, "posts/**/*.md"},
      #{}
    }
  }.
```

Neat! More or less. There is a lot to comment, but first, there is a convention into the creation of the directories:

- `posts`: where we put explicitly posts when we are to create a blog.
- `pages`: where we put the extra pages, like about or the normal pages a website should have.
- `templates`: where we put the templates (usually ErlyDTL at the moment).
- `assets`: where all of the static files should be placed. Be careful if you are using something like webpack, brunch or similar. This should be the destination directory for these tools and not the directory containing all of the generator and node modules directory.

In the same way the default file for the site it's usually `lambdapad.exs` and the configuration (if we are not indicating anything) it's `config.toml`.

## Options

As you can see, at the moment, you can choose between Elixir or Erlang. You can write the way your web site is going to be generated based on those two options. But we can also decide about:

- **Templates**: we can write the templates using one of these options:
  - `erlydtl` (default): it's using [ErlyDTL or Django Templates][DT].
  - `eex`: using [EEx][EEx] library instead ([WIP](https://github.com/altenwald/lambdapad/discussions/3))
  - `wordpress_theme`: yes! we could use Wordpres Themes to build the site ([WIP](https://github.com/altenwald/lambdapad/discussions/4))

- **Configuration**: we can write extracts of data to be in use for our templates, transforms, etc. in these formats:
  - `toml` (default): it's using [TOML][TOML]. Very powerful and simple.
  - `eterm`: Erlang Terms, also easy if you are using the Erlang way.
  - `yaml`: Sometimes it's difficult, sometimes it's easy, but well, you can check it out yourself ([WIP](https://github.com/altenwald/lambdapad/discussions/6)).
  - `json`: Not good for humans but, hey! if you have a generated JSON, why not using it in the static web generator? ([WIP](https://github.com/altenwald/lambdapad/discussions/7))
  - `markdown`: well, this is not a configuration system indeed, but it's a way to inject documents as variables to be in use into the templates when they are secondary ([WIP](https://github.com/altenwald/lambdapad/discussions/9))

- **Script**: as we said from the very begining we are using Erlang and Elixir. I've no plans at the moment to increase the number of languages to write these scripts, but based on the languages available on top of BEAM, we could do something to integrate PHP, OCaml, Gleam, Lua, or another. If you want... no, if you really want to get any one of these working on Lambdapad, [open a discussion](https://github.com/altenwald/lambdapad/discussions).

- **Documents**: when we are defining the documents which could be in use for generating pages, we are indicating mainly Markdown files. At this moment these are the only on document format supported and there is no intention to include more in near future. Markdown is ok.

## Configuration Blocks (Elixir)

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
- `excerpt` (boolean) is telling if the markdown files have excerpt or not. Even if they have no excerpt and we configure this value to `true` the code is getting the first paragraph as excerpt. Default value is `true`.
- `var_name` (string | :plain) it's setting the list of pages using the name provided here to be in use into the template. The default value is `:plain`.
- `format` (:erlydtl) yes, it makes no sense to put this value at the moment, but in near future it's desirable to have also support for other template engines like `:eex`. [Keep in touch!][EEx].
- `env` (map) it's letting us to define extra parameters for the template in a map format (see pages example for further information).

**Note** that if the `from` is retrieving different files, it will generate a list of elements which cannot be merge with the list of values, therefore `:plain` will be changed automatically to `"pages"` giving a warning.

The generation of the widgets is inserted into the configuration under the key `widgets`. But it's even easier to use, when we are into the template we have only to use:

```htmldjango
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
- `excerpt` (boolean) is telling if the markdown files have excerpt or not. Even if they have no excerpt and we configure this value to `true` the code is getting the first paragraph as excerpt. Default value is `true`.
- `var_name` (string | `:plain`) it's setting the list of pages using the name provided here to be in use into the template. The default value is `:plain`.
- `format` (`:erlydtl`) yes, it makes no sense to put this value at the moment, but in near future it's desirable to have also support for other template engines like `:eex`. [Keep in touch!][EEx].
- `env` (map) it's letting us to define extra parameters for the template in a map format:

  ```elixir
  set env: %{
    "environment" => System.get_env("LPAD_ENV") || "dev"
  }
  ```

- `priority` (`:high` | `:normal` | `:low`) indicates when the page will be generated. It's useful when we want to use `transform_to_persist` and generate `sitemaps` at the end of the generation of the blog.

The way the pages are rendered into the files depends on the configuration. But mainly they follow these steps:

1. The pages are retrieved (read) from the place we have configure (`from`). But even it's possible avoid this and only render a template without specific content. This step is optional.
2. The pages are processed item by item (using `transforms_on_item`). If there are no pages from step 1 this step is ommited.
3. The pages are processed as a whole (using `transform_on_page`). If there are no pages from step 1 this step is ommited.
4. The config is processed based on the pages (using `transform_on_config`). If there are no pages from step 1 this step is ommited.
5. The page is rendered using the template and appliying the widgets.
6. File is written using the render page.
7. The page data is processed by the `transform_to_persist` function and modify the configuration for the specific URL. If the `pages` generates several files, then several URLs are going to be saved into the `url_data` configuration.

## Configuration functions (Erlang)

If we choose to write our static site using Erlang, we have to create the module as `index.erl`. Indeed, the name could be changed, but I think `index.erl` it's a good name and it's not colliding with anything, but feel free to change it to `blog.erl` or whatever else.

**Note** that it's not needed export functions, the compilation will do that for us.

### `config/1`

This function is optional. It's receiving the arguments we passed to `lpad` script. These are not needed strictly but it could be useful, just in case.

The return of the function MUST be a map containing atoms as keys and tuples with two elements, or we can return a list of two elements tuples:

```erlang
-type kind() :: eterm | toml.
-type filename() :: string().
-spec config([string()]) -> #{ atom() => {kind(), filename()}} | [{kind(), filename()}].
```

An example:

```erlang
config(_Args) ->
  #{
    blog => {eterm, "blog.config"}
  }.
```

This configuration is searching for `blog.config` file, opening it as Erlang Term file, parsing and putting the whole content into the `"blog"` key for the configuration result. If the content of the file is as follows:

```erlang
#{ url => "https://myblog.com/" }.
```

After retrieving the configuration we will have:

```erlang
#{
  <<"blog">> => #{
    <<"url">> => "https://myblog.com/"
  }
}
```

Of course, you can choose `toml` format and it's working in the same way.

### `assets/1`

This function is optional. It's accepting the configuration data as the only one parameter. We have to define the assets we want to copy in the following way:

```erlang
assets(_Config) ->
  #{
    files => {"assets/*.css", "site/css"}
  }.
```

In the previous example, this is copying from the `assets` directory whatever file which have the `css` extension to the `site/css` directory. Easy, right? You can define as many entries as you need. By default the function is as follows:

```erlang
assets(_Config) ->
  #{ general => {"assets/**", "site/"} }.
```

If that's good for you, you can avoid define this function.

## `widgets/1`

The definition of the widgets is similar to the definition of the pages. But they are not written into the disk so, they need to get a name. The specification for the data we could use is as follows:

```erlang
-type template() :: string().
-type var_name() :: atom().
-type from_files() :: string().
-type extra_data() :: #{ atom() => term() }.

-type widget_name() :: string().
-type widget_content() ::
  {
    template | template_map,
    template(),
    {var_name(), from_files()},
    extra_data()
  }.

-spec widgets(Config :: term()) -> #{ widget_name() => widget_content() }.
```

An implementation example could be checked here:

```erlang
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
```

We are getting each entry from the map as the name (key) and the data (value). The data is a 4-element tuple which defines an action (`template` or `template_map`), a template file, a 2-element tuple defining the new entry into the data (for the template) where the files defined as the second element of the tuple are going to be available and finally extra data to be included into the definition.

As we said, the `action` could be:
- `template`: this is setting the `index` to `true` and retrieving all of the files in only one template. Only one file is going to be generated.
- `template_map`: this is setting the `index` to `false` and generates a file for each file found with the wildcard parameter.

The `template` (second parameter into the tuple) should be a valid file into the `templates` directory.

The tuple composing `var_name` and `from` (files to match and use into the templates), are setting these parameters so, every file should be included into the template using the key `var_name` (it's working only with Markdown at the moment, it's not possible read other kind of files).

And finally, the map where we could define the rest of configuration. The configuration is like we saw above into the configuration block for `pages`, you read it to get more information. As you can see into the example, we are using the `env` parameter but we could use others like `transform_on_page`, `transform_on_item` or `transform_on_config`.

### `pages/1`

This function is required. If the function isn't found into the module, it will trigger an error. The definition of the function is exactly the same as we saw previously for widgets:

```erlang
-type template() :: string().
-type var_name() :: atom().
-type from_files() :: string().
-type extra_data() :: #{ atom() => term() }.

-type page_name() :: string().
-type page_content() ::
  {
    template | template_map,
    template(),
    {var_name(), from_files()},
    extra_data()
  }.

-spec pages(Config :: term()) -> #{ page_name() => page_content() }.
```

Read the definition for the data into the previous section.

## Output Directory

By convention, it's assumed we are putting our generated website into `site` directory. We can change this in every configuration using the following:

```toml
[blog]
output_dir = "public"
```

In this case, instead of use `site` we are going to place all of the generated pages into `public`.

**Note** that when you change this you have to perform the same change into `assets`, because `assets` is not using this configuration.

### Posts and Pages

We are using [Markdown][MD] for writing the docs and these markdown files have a header which usually should content the following fields for `posts`:

```
id: hello-world
title: Hello World!
author: Manuel Rubio

Hello world! This is my blog!
```

And then you can write the content keeping an empty (or blank) line between the header and the content.

**Note** that we are checking at this moment for `\n\n` so, keep in mind to format your markdown texts as `LF` instead of `CRLF` or `CR`.

For pages, it's only required the `id` the rest of information could be useful only in case you are going to need it inside of your page from the template.

The header isn't mandatory but if we want to skip it, we have to configure for the page or the widget the correspondent:

```elixir
set headers: false
```

Whe we skip the header the `id` is set as the name of the file removing the extension.

In the same way, we can write a content which have included an excerpt:

```
This is the excerpt of my post.
<!--more-->

This is the rest of my post.
```

The `<!--more-->` tag is giving to Lambdapad the indication for where it should be cut to get the excerpt. If we are using:

```elixir
set excerpt: true
```

But we are not using the mark:

```
This is the first paragraph.

This is the second paragraph.
```

Lambdapad is choosing the first paragraph as the excerpt automatically.

### Templates

At this moment we support only [ErlyDTL][ED] for templates. This is based on [Django Templates][DT] and in use for different systems in the Python ecosystem.

Depending on the configuration you use, you could have different information available into the template. The configuration from `config.toml` is inserted as is into the template so, for example, the information into the section `blog` for `url` could be accesible using:

```htmldjango
{{ blog.url }}
```

And if we configure `var_name` for posts as `"posts"`, we can find a list of posts retrieved from the amount of files we have into the `posts/**.md` searching wildcard as:

```htmldjango
{% for post in posts %}
<div class='post'>
  <h1><a name='#{{ post.id }}'>{{ post.title }}</a></h1>
  {{ post.excerpt }}
</div>
{% endfor %}
```

Lambdapad also insert information inside of the template if you want to use it like this:

```htmldjango
<generator uri="{{ lambdapad.url }}" version="{{ lambdapad.vsn }}">{{ lambdapad.name }}</generator>
```

- `name` is set as `Lambdapad`
- `url` is set as https://lambdapad.com
- `vsn` is set as the version number of the Lambdapad in use, at this moment: `0.1.0`
- `description` is set as `Static website generator`

From every post we have also, and usually, available the following data:

- `excerpt`: it's the text choosen as excerpt. If we configure the excerpt as false then it's going to be empty. It's clean text and all of the possible tags (i.e. strong, em or links) are removed.
- `excerpt_html`: it's the HTML version of the excerpt.
- `content`: the HTML content for the page.
- `id`: it could be given from headers or set by Lambdapad if we disabled headers.

### Assets

By default, if we are not indicating anything, the configuration block understood by the system is this one:

```elixir
assets "general" do
  set from: "assets/**"
  set to: "site/"
end
```

This is meaning to copy everything from `assets` directory into the `site` directory.

## HTTP Server

Because it's easier if we can access directly the generated site, we are providing a subcommand to help you navigate through the generate pages:

```
lpad http
```

This is reading the `lambdapad.exs` file and reading the generated files from the place where they were generated. You can configure it with a different port and even with a different `lambdapad.exs` file:

```
lpad http -p 8000 myblog/lambdapad.exs
```

## New (Templates)

This feature is still experimental... more than the rest of the project, I mean. It's a way to generate the skeleton of a project in a fast way. It's using the blog sample at the moment to generate the new project. You can try:

```
lpad help new
```

## Contributing

Yes! Please! :-) ... you can clone, perform changes and send a pull request via Github. It's not difficult.

If you prefer to say what do you think it's missing or could be improved, please, open an issue ticket and explain as better as possible what do you need/want/desire.

In all of the cases, sponsorship the project it's possible and we'll open a sponsor section here as soon as we receive the request to be included with the payment via Github, PayPal or Patreon.

[MD]: https://daringfireball.net/projects/markdown/syntax
[ED]: https://github.com/erlydtl/erlydtl
[DT]: https://docs.djangoproject.com/en/3.1/topics/templates
[TOML]: https://github.com/toml-lang/toml
[EEx]: https://hexdocs.pm/eex/EEx.html
