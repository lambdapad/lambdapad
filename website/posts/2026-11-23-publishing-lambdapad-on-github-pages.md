id: publishing-lambdapad-on-github-pages
date: 2026-11-23
title: Publishing a Lambdapad Site on GitHub Pages
author: manuel
type: Tutorial

Once your Lambdapad site is building locally, deploying it to **GitHub Pages** takes just one GitHub Actions workflow. You do not need to commit generated HTML into a `gh-pages` branch—GitHub Actions builds `site/` on every push and publishes it directly.

<!--more-->

## 1. Set Your Production URL in `config.toml`

Before deploying, make sure `config.toml` points to your live URL so Open Graph tags, links, and RSS feeds use the right domain:

```toml
[blog]
url = "https://lambdapad.com/"
title = "Lambdapad"
description = "Static website generator using Elixir or Erlang"
```

If you are using a custom domain, keep a `CNAME` file in your project root (or `website/CNAME`) with your domain name.

## 2. Enable GitHub Pages with GitHub Actions

In your repository on GitHub, open **Settings → Pages** and set **Source** to **GitHub Actions**.

## 3. Add `.github/workflows/deploy-pages.yml`

Here is the workflow we use for `lambdapad.com` itself. It sets up Erlang/OTP and Elixir, runs `lpad`, preserves `CNAME`, and publishes `site/` using the official Pages actions:

```yaml
name: Deploy site

on:
  push:
    branches: [ "master" ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: true

jobs:
  build:
    name: Build the website with lpad
    runs-on: ubuntu-22.04

    steps:
      - uses: actions/checkout@v4
      - name: Set up Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.20.4'
          otp-version: '29.0.5'
      - name: Generate the website
        run: ./lpad lambdapad.exs
      - name: Preserve the custom domain
        run: cp CNAME site/CNAME
      - name: Upload the generated site
        uses: actions/upload-pages-artifact@v3
        with:
          path: site

  deploy:
    name: Deploy to GitHub Pages
    needs: build
    runs-on: ubuntu-22.04
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}

    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

If you do not want to commit the `lpad` binary to your repository, you can either download it during the workflow or build it from source with `MIX_ENV=prod mix escript.build`—which is exactly what we do in the main `lambdapad` repository.

## 4. Push and Verify

Push to your default branch and check the **Actions** tab. Within a minute, your site—along with Tailwind CSS, esbuild bundles, docs, blog posts, and `/blog/rss.xml`—will be live on GitHub Pages.
