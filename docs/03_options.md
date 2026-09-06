id: options
date: 2022-05-16
updated: 2025-10-28
title: Options for Configuration
group: Core Concepts

[DT]: https://docs.djangoproject.com/en/3.1/topics/templates
[TOML]: https://github.com/toml-lang/toml
[EEx]: https://hexdocs.pm/eex/EEx.html

As you can see, at the moment, you can choose between Elixir or Erlang. You can write the way your web site is going to be generated based on those two options. But we can also decide about:

- **Templates**: we can write the templates using one of these options:
  - `erlydtl` (default): it's using [ErlyDTL or Django Templates][DT].
  - `eex`: using [EEx][EEx] library instead.
  - `wordpress_theme`: yes! we could use Wordpress Themes to build the site ([WIP](https://github.com/lambdapad/lambdapad/discussions/4))

- **Configuration**: we can write extracts of data to be in use for our templates, transforms, etc. in these formats:
  - `toml` (default): it's using [TOML][TOML]. Very powerful and simple.
  - `eterm`: Erlang Terms, also easy if you are using the Erlang way.

- **Script**: as we said from the very beginning we are using Erlang and Elixir. I think we don't need to add more and even it could be more complicated and overloading to keep more languages to do the same, however if you feel there's a language that fits like [Luerl](https://luerl.org/) or [ephp](https://github.com/bragful/ephp) just [open a discussion](https://github.com/lambdapad/lambdapad/discussions).

- **Documents**: when we are defining the documents which could be in use for generating pages, we are indicating mainly Markdown files. At this moment these are the only on document format supported and there is no intention to include more in near future. Markdown is ok.
