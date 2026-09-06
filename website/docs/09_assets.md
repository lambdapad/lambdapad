id: assets
date: 2025-03-14
title: Assets
group: Core Concepts

By default, if we are not indicating anything, the configuration block understood by the system is this one:

```elixir
assets "general" do
  set from: "assets/**"
  set to: "site/"
end
```

This is meaning to copy everything from `assets` directory into the `site` directory.

## Tools

~_New in 0.11.0_~

Because usually assets are generated using tools like `esbuild` or `tailwind` we added these tools and you can use them to generate the JavaScript code (using `esbuild`) and CSS code (using `tailwind`). Let's going to see how we could use both of them.

### JavaScript using Esbuild

Handling assets using esbuild tool. These assets will be handled one by one, as they are put in the configuration. The configuration should be something like:

```elixir
assets "js" do
  set from: "assets/**/*.js"
  set to: "site/"
  set tool: :esbuild
end
```

As you can see, we need only to provide the `tool` configuration. But we can do even further configurations providing the key `esbuild`:

```elixir
assets "js" do
  set from: "assets/**/*.js"
  set to: "site/"
  set tool: :esbuild
  set esbuild: [
    # esbuild version to be in use
    version: "0.25.0",

    # esbuild path for the binary
    path: "#{__DIR__}/bin/esbuild",

    # esbuild target option
    target: "es2016",

    # esbuild extra args for command
    extra_args: ~w(--verbose)
  ]
end
```

### CSS using Tailwind

The tailwind CSS tool is helping us to use tailwind for handling our CSS files so we can use it in the configuration using the following config:

```elixir
assets "css" do
  set from: "assets/**/*.css"
  set to: "site/"
  set tool: :tailwind
end
```

As you can see, we need only provide `tool` key with the content `:tailwind`. We can also provide more arguments for the tailwind command as follows:

```elixir
assets "css" do
  set from: "assets/**/*.css"
  set to: "site/"
  set tool: :tailwind
  set tailwind: [
    # tailwind version to install
    version: "4.0.9",

    # tailwind path to install the binary
    path: "#{__DIR__}/bin/tailwind",

    # tailwind extra args
    extra_args: ~w(--optimize --minify)
  ]
end
```

### JavaScript packages with NPM

We can also use `package.json` for installing the desired JavaScript packages for our frontend. A specific block can be defined as:

```elixir
assets "node_modules" do
  set from: "package.json"
  set tool: :npm
end
```

In difference of the previous ones, this doesn't need `to` configuration and even the `from` configuration is a bit tricky because it's not possible to use a different filename that's not called `package.json`. We are getting only the path where the file is.

We could even provide more configuration just in case we have the NPM installed in a different place and it's not configured in our PATH:

```elixir
assets "node_modules" do
  set from: "package.json"
  set tool: :npm
  set npm: [
    path: "/usr/local/npm/bin/npm"
  ]
end
```
