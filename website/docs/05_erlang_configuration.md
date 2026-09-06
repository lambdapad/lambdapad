id: erlang-configuration
date: 2022-05-16
title: Erlang Configuration
group: Core Concepts

Everything is defined into two different files. The first one is the script in use to define what's going to take place (`index.erl`) and the other file is the configuration to get easier change parameters (`blog.config`). Both are necessary into your directory. The usual content for `blog.config` is as follows:

```erlang
#{
  url => "http://localhost:8080",
  title => "My Blog",
  description => "I put my ideas here... what else?"
}
```

You can add as many deep levels as you need, but we recommend to keep it as simple as possible.

You'll need also define information inside of `index.erl` to know what to generate:

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

In the same way the default file for the site it's usually `index.erl` and the configuration (if we are not indicating anything) it's `blog.config`.

## Configuration functions

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
