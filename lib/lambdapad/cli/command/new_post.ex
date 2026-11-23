defmodule Lambdapad.Cli.Command.NewPost do
  @moduledoc """
  New post command. It help us to create a new blog post based on the command
  line options, configurations inside of the config file and default values.
  """

  use Lambdapad.Cli.Command
  alias Lambdapad.{Blog, Cli, Config}
  alias Lambdapad.Cli.Tui

  @default_template_headers %{
    "id" => ~S"#{slug}",
    "title" => nil,
    "subtitle" => nil,
    "date" => ~S"#{year}-#{month}-#{day}",
    "author" => nil,
    "comments" => nil,
    "category" => nil,
    "tags" => nil,
    "featured" => nil,
    "background" => nil
  }

  @default_posts_path ~S"posts/#{yyyy}/#{mm}/#{dd}/#{slug}.md"

  @user_interrupt_code 137

  @impl Lambdapad.Cli.Command
  def options do
    [
      name: "new-post",
      about: "Create a new post inside of the posts directory based on the format",
      flags:
        [
          interactive: [
            short: "-i",
            long: "--interactive",
            help: "Launch interactive wizard / request confirmation of data",
            multiple: false
          ]
        ] ++ Cli.get_verbosity_options(),
      options: [
        date: [
          value_name: "DATE",
          short: "-d",
          long: "--date",
          help: "Date for the post, by default it is the current date",
          parser: :string,
          required: false
        ],
        "posts-dir": [
          value_name: "POSTS_DIR",
          short: "-p",
          long: "--posts-dir",
          help: "Directory where the posts will be created",
          parser: :string,
          required: false
        ],
        bind: [
          value_name: "BIND",
          short: "-b",
          long: "--bind",
          help: "Bind a value for, it should be like key=value",
          parser: fn value when is_binary(value) ->
            case String.split(value, "=", parts: 2) do
              [key, value] -> {:ok, {key, value}}
              _ -> {:error, "Format key=value not followed!"}
            end
          end,
          required: false,
          multiple: true
        ]
      ],
      args:
        [
          name: [
            value_name: "name",
            help: "Specify the ID (slug) for the post (optional when using the interactive TUI).",
            parser: :string,
            required: false
          ]
        ] ++ Cli.get_infile_options()
    ]
  end

  @impl Lambdapad.Cli.Command
  def get_name, do: :"new-post"

  @impl Lambdapad.Cli.Command
  def command(%{infile: lambdapad_file, rawargs: rawargs} = params) do
    workdir = Cli.cwd!(lambdapad_file)

    Application.put_env(:lambdapad, :workdir, workdir)
    Application.put_env(:lambdapad, :loglevel, params[:loglevel])

    gt = Cli.print_level1("Reading configuration", lambdapad_file)

    t = Cli.print_level2("Compiling", lambdapad_file)
    {:ok, mod} = Blog.Base.compile(lambdapad_file)
    Cli.print_level2_ok()

    {:ok, config} = Config.init(Blog.Base.get_configs(mod, rawargs), workdir)

    name = params[:name]
    interactive? = params[:interactive]

    cond do
      (is_nil(name) or interactive?) and Tui.supported?() ->
        run_tui_wizard(config, params, workdir, t, gt)

      is_nil(name) ->
        Cli.print_error(
          "Missing post name. Run inside an interactive terminal (OTP 28+) for the wizard, or pass a slug: lpad new-post my-post"
        )

        Cli.halt(1)

      true ->
        run_classic(name, interactive?, config, params, workdir, t, gt)
    end
  end

  defp run_classic(name, interactive?, config, params, workdir, t, gt) do
    name = get(:string, interactive?, "name/slug", name)

    date =
      if date = params[:date] do
        get(:date, interactive?, "date", Date.from_iso8601!(date))
      else
        get(:date, interactive?, "date", Date.utc_today())
      end

    bindings =
      for {key, value} <- params[:bind] || [] do
        {String.to_atom(key), value}
      end ++
        [
          date: date,
          day: date.day,
          month: date.month,
          year: date.year,
          dd: String.pad_leading(to_string(date.day), 2, "0"),
          mm: String.pad_leading(to_string(date.month), 2, "0"),
          yyyy: to_string(date.year),
          slug: name,
          name: name
        ]

    headers = config["blog"]["template_headers"] || @default_template_headers

    {max_size, filled_headers} =
      Enum.reduce(headers, {0, []}, fn
        {header, nil}, {mx, acc} ->
          value = get(:string, interactive?, header, "")
          {max(String.length(header), mx), [{header, value} | acc]}

        {header, value}, {mx, acc} ->
          {value, _} =
            try do
              Code.eval_string(~s|"#{value}"|, bindings)
            rescue
              ce in CompileError ->
                Cli.print_error(
                  "during evaluation of \"#{header}\" in the configuration file: #{ce.description}"
                )

                {"", nil}
            end

          value = get(:string, interactive?, header, value)
          {max(String.length(header), mx), [{header, value} | acc]}
      end)

    content =
      Enum.reduce(filled_headers, "", fn {header, value}, txt ->
        txt <> String.pad_trailing(header, max_size) <> ": " <> value <> "\n"
      end) <>
        """

        Lorem Ipsum is simply dummy text of the printing and typesetting industry.
        Lorem Ipsum has been the industry's standard dummy text ever since the
        1500s,
        <!--more-->

        when an unknown printer took a galley of type and scrambled it to make a type
        specimen book. It has survived not only five centuries, but also the leap
        into electronic typesetting, remaining essentially unchanged. It was
        popularized in the 1960s with the release of Letraset sheets containing
        Lorem Ipsum passages, and more recently with desktop publishing software
        like Aldus PageMaker including versions of Lorem Ipsum.
        """

    path_fmt =
      config["blog"]["posts_path"] ||
        params[:"posts-dir"] ||
        @default_posts_path

    {rel_path, _} = Code.eval_string(~s|"#{path_fmt}"|, bindings)
    path = Path.join([workdir, rel_path])
    write_post_file(path, content, t, gt)
  end

  defp write_post_file(path, content, t, gt) do
    Cli.print_level2("Create directory")
    relative_output_dir = Path.dirname(path)
    Cli.print_level3(relative_output_dir)
    File.mkdir_p!(relative_output_dir)
    Cli.print_level2_ok()
    Cli.print_level1_ok(t)

    t = Cli.print_level1("Create source for post")
    relative_file = Path.basename(path)
    Cli.print_level2(relative_file)
    File.write!(path, content)
    Cli.print_level2_ok()
    Cli.print_level1_ok(t)
    :ok = Cli.done(gt)
  end

  defp run_tui_wizard(config, params, workdir, t, gt) do
    Tui.banner("Create a new Lambdapad post", "Esc or Ctrl+C to cancel at any time.")

    with {:ok, title} <- Tui.prompt_text("What is the title of your post?", required: true),
         {:ok, slug} <- ask_slug(params[:name] || Tui.slugify(title)),
         {:ok, date} <- ask_date(params[:date]),
         {:ok, author} <- ask_author(config),
         {:ok, type_val} <- ask_type(),
         {:ok, header_lines} <- build_tui_headers(title, slug, date, author, type_val, config),
         path_fmt = config["blog"]["posts_path"] || params[:"posts-dir"] || @default_posts_path,
         bindings = build_bindings(slug, date),
         {rel_path, _} = Code.eval_string(~s|"#{path_fmt}"|, bindings),
         :ok <- confirm_creation(rel_path, header_lines) do
      content =
        Enum.join(header_lines, "\n") <>
          "\n\nWrite your summary here.\n\n<!--more-->\n\nWrite the rest of your post here.\n"

      path = Path.join([workdir, rel_path])
      write_post_file(path, content, t, gt)

      IO.puts([
        "\n  ",
        IO.ANSI.green(),
        "Next step: ",
        IO.ANSI.reset(),
        "edit ",
        rel_path,
        " and run ",
        IO.ANSI.cyan(),
        "lpad http",
        IO.ANSI.reset(),
        " to preview it in your browser.\n"
      ])
    else
      :cancel ->
        IO.puts("\n  Cancelled. No files were created.\n")
        Cli.halt(@user_interrupt_code)
    end
  end

  defp ask_slug(default_slug) do
    Tui.prompt_text("URL name (slug)",
      default: default_slug,
      hint: "Used in the post link (e.g. /blog/#{default_slug}). Press Enter to accept.",
      required: true,
      validator: fn val ->
        if val =~ ~r/^[a-z0-9][a-z0-9-]*$/,
          do: :ok,
          else: {:error, "Use only lowercase letters, numbers, and hyphens."}
      end
    )
  end

  defp ask_date(nil) do
    today = Date.utc_today()
    tomorrow = Date.add(today, 1)
    days_to_mon = rem(8 - Date.day_of_week(today), 7)
    next_mon = Date.add(today, if(days_to_mon == 0, do: 7, else: days_to_mon))

    options = [
      {"Today (#{today})", today},
      {"Tomorrow (#{tomorrow})", tomorrow},
      {"Next Monday (#{next_mon})", next_mon},
      {"Enter a custom date", :custom}
    ]

    case Tui.prompt_select("Publish date", options) do
      {:ok, :custom} -> ask_custom_date(today)
      other -> other
    end
  end

  defp ask_date(date_str), do: {:ok, Date.from_iso8601!(date_str)}

  defp ask_custom_date(default_date) do
    case Tui.prompt_text("Custom date (YYYY-MM-DD)",
           default: to_string(default_date),
           required: true,
           validator: fn val ->
             case Date.from_iso8601(val) do
               {:ok, _} -> :ok
               {:error, _} -> {:error, "Invalid date. Use YYYY-MM-DD (e.g. #{default_date})."}
             end
           end
         ) do
      {:ok, str} -> {:ok, Date.from_iso8601!(str)}
      :cancel -> :cancel
    end
  end

  defp ask_author(config) do
    authors = Map.get(config, "authors", %{})

    if map_size(authors) == 0 do
      {:ok, nil}
    else
      options = Enum.map(authors, &author_option/1) ++ [{"No author", nil}]
      Tui.prompt_select("Author", options)
    end
  end

  defp author_option({key, %{"name" => name}}), do: {"#{name} (#{key})", key}
  defp author_option({key, _info}), do: {key, key}

  defp ask_type do
    options = [
      {"Tutorial", "Tutorial"},
      {"Architecture", "Architecture"},
      {"Engineering", "Engineering"},
      {"Announcement", "Announcement"},
      {"Custom...", :custom},
      {"Skip", nil}
    ]

    case Tui.prompt_select("Category / Type", options) do
      {:ok, :custom} -> Tui.prompt_text("Custom category / type", required: true)
      other -> other
    end
  end

  defp build_tui_headers(title, slug, date, author, type_val, config) do
    base =
      [
        {"id", slug},
        {"date", Date.to_iso8601(date)},
        {"title", title},
        if(author, do: {"author", author}),
        if(type_val, do: {"type", type_val})
      ]
      |> Enum.reject(&is_nil/1)

    extra_keys =
      (config["blog"]["template_headers"] || %{})
      |> Map.keys()
      |> Enum.reject(&(&1 in ["id", "date", "title", "author", "type"]))

    with {:ok, extras} <- maybe_ask_extras(extra_keys) do
      all = base ++ extras
      max_len = all |> Enum.map(fn {k, _} -> String.length(k) end) |> Enum.max(fn -> 0 end)
      lines = Enum.map(all, fn {k, v} -> String.pad_trailing(k, max_len) <> ": " <> v end)
      {:ok, lines}
    end
  end

  defp maybe_ask_extras([]), do: {:ok, []}

  defp maybe_ask_extras(keys) do
    case Tui.prompt_select("Optional metadata (#{Enum.join(keys, ", ")})?", [
           {"Skip optional fields", :skip},
           {"Fill optional fields", :fill}
         ]) do
      {:ok, :skip} -> {:ok, []}
      {:ok, :fill} -> fill_extra_fields(keys)
      :cancel -> :cancel
    end
  end

  defp fill_extra_fields(keys) do
    Enum.reduce_while(keys, {:ok, []}, fn key, {:ok, acc} ->
      case Tui.prompt_text(key) do
        {:ok, ""} -> {:cont, {:ok, acc}}
        {:ok, val} -> {:cont, {:ok, acc ++ [{key, val}]}}
        :cancel -> {:halt, :cancel}
      end
    end)
  end

  defp confirm_creation(rel_path, header_lines) do
    Tui.preview_box("File: #{rel_path}", header_lines)

    case Tui.prompt_select("Ready to create this post?", [
           {"Create post", :create},
           {"Cancel", :cancel}
         ]) do
      {:ok, :create} -> :ok
      _ -> :cancel
    end
  end

  defp build_bindings(slug, date) do
    [
      date: date,
      day: date.day,
      month: date.month,
      year: date.year,
      dd: String.pad_leading(to_string(date.day), 2, "0"),
      mm: String.pad_leading(to_string(date.month), 2, "0"),
      yyyy: to_string(date.year),
      slug: slug,
      name: slug
    ]
  end

  defp get(_, false, _name, value), do: value

  defp get(:date, true, name, nil) do
    IO.gets("#{name}> ")
    |> String.trim()
    |> Date.from_iso8601()
    |> case do
      {:ok, date} ->
        get(:date, true, name, date)

      {:error, _} ->
        IO.puts("invalid date, please use format YYYY-MM-DD")
        get(:date, true, name, nil)
    end
  end

  defp get(:string, true, name, nil) do
    IO.gets("#{name}> ")
    |> String.trim()
    |> then(&get(:string, true, name, &1))
  end

  defp get(kind, true, name, default) do
    IO.gets("#{name} is #{inspect(to_string(default))}, change? (y)es (N)o (c)ancel ")
    |> String.trim()
    |> case do
      resp when resp in ["", "n", "N"] ->
        default

      resp when resp in ["y", "Y"] ->
        get(kind, true, name, nil)

      resp when resp in ["c", "C"] ->
        Cli.halt(@user_interrupt_code)

      _otherwise ->
        IO.puts("cannot understand input")
        get(kind, true, name, default)
    end
  end
end
