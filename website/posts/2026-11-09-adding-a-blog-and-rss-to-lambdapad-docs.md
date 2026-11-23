id: adding-a-blog-and-rss-to-lambdapad-docs
date: 2026-11-09
title: Adding a Blog and RSS Feed to a Lambdapad Docs Site
author: manuel
type: Tutorial
image: /images/blog/adding-a-blog-and-rss-to-lambdapad-docs.jpg

This website started with a landing page, documentation under `/docs`, and static pages like `/about`. Adding a full blog with clean SEO-friendly URLs and an RSS 2.0 feed only takes a few lines in `lambdapad.exs` and three templates.

<!--more-->

## 1. Choosing SEO-Friendly URLs

For technical articles and release notes, keeping URLs short and evergreen matters. Rather than embedding dates in every permalink (`/2026/11/16/...`), each post lives at `/blog/{{ post.id }}`:

```elixir
pages "posts" do
  set(from: :posts)
  set(uri: "/blog/{{ post.id }}")
  set(var_name: "post")
  set(excerpt: false)
  set(headers: true)
  set(template: "post.html")
  set(transform_on_item: ["date", "author"])
end
```

This keeps links concise, avoids making updated guides look outdated in search results, and cleanly separates blog content from `/docs`.

## 2. Building the `/blog` Index

To render the main blog listing, we configure an index page with `index: true`, `excerpt: true`, and `order by date desc` from `extensions/postinfo.exs`:

```elixir
pages "blog" do
  set(from: :posts)
  set(uri: "/blog")
  set(var_name: "posts")
  set(index: true)
  set(excerpt: true)
  set(template: "blog.html")
  set(transform_on_item: ["date", "author"])
  set(transform_on_page: ["order by date desc"])
end
```

## 3. Generating `/blog/rss.xml`

By default, Lambdapad writes directory-style URLs (`/blog/index.html`). For feeds, sitemaps, or any non-HTML output, setting `uri_type: :file` tells Lambdapad to write the exact file path instead:

```elixir
pages "rss" do
  set(from: :posts)
  set(uri: "/blog/rss.xml")
  set(uri_type: :file)
  set(var_name: "posts")
  set(index: true)
  set(excerpt: true)
  set(template: "rss.xml")
  set(transform_on_item: ["date", "author"])
  set(transform_on_page: ["order by date desc"])
end
```

Pair that with a `<link rel="alternate" type="application/rss+xml" href="/blog/rss.xml" />` tag in `head.html`, and feed readers can auto-discover the blog from any page on the site.
