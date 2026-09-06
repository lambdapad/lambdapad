id: pages
date: 2022-05-16
title: Posts and Pages
group: Core Concepts

[MD]: https://daringfireball.net/projects/markdown/syntax

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

And the mark is present, the text before it is used as the excerpt. But if we are not using the mark:

```
This is the first line.
This is still the same paragraph.

This is the second paragraph.
```

Lambdapad falls back to the first **line** of the content, not the whole first paragraph. In the example above the excerpt would only be `This is the first line.`, so if your first paragraph spans more than one line, use `<!--more-->` explicitly instead of relying on the fallback.
