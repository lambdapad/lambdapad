id: output-directory
date: 2022-05-16
title: Output Directory
group: Core Concepts

By convention, it's assumed we are putting our generated website into `site` directory. We can change this in every configuration using the following:

```toml
[blog]
output_dir = "public"
```

In this case, instead of use `site` we are going to place all of the generated pages into `public`.

**Note** that when you change this you have to perform the same change into `assets`, because `assets` is not using this configuration.
