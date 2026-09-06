id: http-server
date: 2022-05-16
title: HTTP Server
group: Running

Because it's easier if we can access directly the generated site, we are providing a subcommand to help you navigate through the generate pages:

```
lpad http
```

This is reading the `lambdapad.exs` file and reading the generated files from the place where they were generated. You can configure it with a different port and even with a different `lambdapad.exs` file:

```
lpad http -p 8000 myblog/lambdapad.exs
```
