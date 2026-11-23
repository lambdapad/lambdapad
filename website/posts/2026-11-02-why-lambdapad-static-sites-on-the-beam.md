id: why-lambdapad-static-sites-on-the-beam
date: 2026-11-02
title: Why Lambdapad: Static Sites on the BEAM
author: manuel
type: Architecture
image: /images/blog/why-lambdapad-static-sites-on-the-beam.jpg

Most static site generators ask you to choose between rigid conventions and sprawling plugin ecosystems. Lambdapad takes a different approach: a declarative configuration DSL running on the BEAM, paired with ErlyDTL templates and a single standalone CLI binary.

<!--more-->

## A Declarative Pipeline, Not a Black Box

In Lambdapad, your entire site is described in a single `lambdapad.exs` (or `lambdapad.erl`) file. Instead of scattering magic conventions across hidden directories, you explicitly declare:

- **Sources** (`posts`, `pages`, `docs`) using glob patterns over Markdown files.
- **Pages and Indexes**, mapping each source to a URI pattern, template, and item/page transforms.
- **Widgets**, such as a documentation table of contents generated from headings.
- **Asset pipelines**, orchestrating `npm`, `esbuild`, and `tailwind` directly during the build.

This explicitness makes it straightforward to combine a landing page, a multi-page documentation portal, and a blog in the exact same project.

## Why Erlang and Elixir?

Building on the BEAM gives Lambdapad fast parallel generation, clean data transformations in pure Elixir or Erlang, and battle-tested Django-style templates via **ErlyDTL**.

When you need custom behavior—like formatting dates, resolving author metadata from `config.toml`, or grouping posts by year—you do not need a heavy plugin framework. A few lines in an `.exs` extension file give you full access to the item or page list as plain maps.

## Zero-Hassle Distribution with `lpad`

For day-to-day writing and CI/CD pipelines, you should not have to maintain a full local toolchain just to build your docs or blog. The `lpad` binary packages Lambdapad into a single executable so you can build and preview your site anywhere—locally or in GitHub Actions—with minimal setup.
