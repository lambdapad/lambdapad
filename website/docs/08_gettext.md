id: gettext
date: 2024-05-05
title: Gettext (i18n)
group: Core Concepts

~_New in 0.10.0_~

Thanks to the [gettext](https://hexdocs.pm/gettext/) project we have the
possibility to use translations for our templates. The function `gettext/1`
is available to be in use for [ErlyDTL and EEx templates](/docs/templates).

The way to proceed is easy. First, you need to create your project and
place some `gettext/1` calls inside of your templates. Then you could be
able to run:

```
$ ./lpad gettext
```

This command will generate the directory `gettext` inside of your project and
the corresponding POT and PO files.

The POT files are the templates and they shouldn't be modified manually.

## Configuration

By default, the only one language to be created is `en`, if you want to provide
more languages you have to add them under the `blog` entry in the
configuration:

```toml
[blog]
# ...
languages = ["en", "es", "fr", "de"]
```

or

```erlang
#{
  % ...
  languages => ["en", "es", "fr", "de"]
}
```

In addition, if you want to change the translations to a different path, you
can use `languages_path`:

```toml
[blog]
# ...
languages_path = "i18n"
```

or

```erlang
#{
  % ...
  languages_path => "i18n"
}
```

## Translating info from Configuration

Usually for Blog we usually put some information inside of the configuration
and because it could be taken directly from there you can't get that translated
automatically via gettext. But, you can use this trick:

```toml
[blog]
# ...
description.en = "This is the description of my blog"
description.es = "Esta es la descripción de mi blog"
# ...
```

or

```erlang
#{
  % ...
  description => #{
    en => "This is the description of my blog",
    es => "Esta es la descripción de mi blog"
  },
  % ...
}
```

In addition, inside of the templates you can use the variable `language`
that will be available for both ErlyDTL (`{{language}}`) and Eex
(`<%= @language %>`).
