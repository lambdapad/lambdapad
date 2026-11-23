id: under-the-hood-padmark-lpad-and-modern-lambdapad
date: 2026-11-16
title: Under the Hood: Padmark, lpad CLI, and Modern Lambdapad
author: manuel
type: Engineering
image: /images/blog/under-the-hood-padmark-lpad-and-modern-lambdapad.jpg

Over the past few weeks we have been tightening up the entire Lambdapad stack—from Markdown parsing and dark-mode rendering on `lambdapad.com` to automated builds and standalone CLI packaging.

<!--more-->

## Meet Padmark

Markdown parsing in Lambdapad is now powered by **Padmark**, our dedicated evolution of Earmark. Moving to Padmark lets us maintain strict quality gates, keep dependencies up to date, and fix edge cases that matter for technical documentation—such as void tag handling, multi-line HTML attributes, and cleaner parser warnings.

## Better Developer Experience on `lambdapad.com`

Along with the new blog and RSS feed, the website itself has received several quality-of-life improvements:

- **Automated GitHub Pages deployment** directly from `website/` via GitHub Actions.
- **Full dark mode support** across documentation, static pages, and now blog posts.
- **Fixed `/download/lpad` asset publishing**, making it straightforward to grab the standalone CLI binary directly from the site.

## What's Next

Now that the blog is live, we will use this space to share release notes, deep dives into ErlyDTL and Padmark internals, and practical recipes for building fast static sites on the BEAM. Subscribe via [RSS](/blog/rss.xml) to follow along.
