id: getting-started
date: 2022-05-16
title: Getting Started
group: Introduction

You need only to get the code, from source code you can:

```
git clone https://github.com/lambdapad/lambdapad
cd lambdapad
mix deps.get
mix escript.build
```

Then you will have the `lpad` script ready. You can copy it to a place accessible from wherever you are or even include it into the directory you have for generate your blog or website.

When you are running `lpad`, this command searches for a `lambdapad.exs` file into the current directory. You can indicate where the file is located, even if you called it in another way:

```
lpad www/myblog/lambdapad.exs
```

Or if you are going to use the Erlang way:

```
lpad www/myblog/index.erl
```
