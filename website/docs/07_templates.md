id: templates
date: 2022-05-16
updated: 2023-06-09
title: Templates
group: Core Concepts

[ED]: https://github.com/erlydtl/erlydtl
[DT]: https://docs.djangoproject.com/en/3.1/topics/templates

We have support for two different ways for creating templates: [ErlyDTL][ED] based on [Django Templates][DT] and [EEx][EEx] based on the Elixir library with the same name.

Depending on the configuration you use, you could have different information available into the template. The configuration from `config.toml` is inserted as is into the template so, for example, the information into the section `blog` for `url` could be accessible using the following code for `erlydtl`:

```django
{{ blog.url }}
```

Or the following code using `eex`:

```elixir
<%= @blog[:url] %>
```

And if we configure `var_name` for posts as `"posts"`, we can find a list of posts retrieved from the amount of files we have into the `posts/**.md` searching wildcard for `erlydtl`:

```django
{% for post in posts %}
<div class='post'>
  <h1><a name='#{{ post.id }}'>{{ post.title }}</a></h1>
  {{ post.excerpt }}
</div>
{% endfor %}
```

Or using `eex`:

```elixir
<%= for post <- @posts do %>
<div class='post'>
  <h1><a name='#<%= post[:id] %>'><%= post[:title] %></a></h1>
  <%= post[:excerpt] %>
</div>
<% end %>
```

Lambdapad also insert information inside of the template if you want to use it like this for `erlydtl`:

```django
<generator uri="{{ lambdapad.url }}" version="{{ lambdapad.vsn }}">{{ lambdapad.name }}</generator>
```

And this for `eex`:

```elixir
<generator uri="<%= @lambdapad[:url] %>" version="<%= @lambdapad[:vsn] %>"><%= @lambdapad[:name] %></generator>
```

- `name` is set as `Lambdapad`
- `url` is set as https://lambdapad.com
- `vsn` is set as the version number of the Lambdapad in use, at this moment: `0.9.0`
- `description` is set as `Static website generator`

From every post we have also, and usually, available the following data:

- `excerpt`: it's the text chosen as excerpt. If we configure the excerpt as false then it's going to be empty. It's clean text and all of the possible tags (i.e. strong, em or links) are removed.
- `excerpt_html`: it's the HTML version of the excerpt.
- `content`: the HTML content for the page.
- `id`: it could be given from headers or set by Lambdapad if we disabled headers.
