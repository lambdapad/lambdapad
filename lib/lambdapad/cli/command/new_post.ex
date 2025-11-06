defmodule Lambdapad.Cli.Command.NewPost do
  @moduledoc """
  New post command. It help us to create a new blog post based on the command
  line options, configurations inside of the config file and default values.
  """

  use Lambdapad.Cli.Command
  alias Lambdapad.{Blog, Cli, Config}

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
      flags: [
        interactive: [
          short: "-i",
          long: "--interactive",
          help: "Request confirmation of data one by one",
          multiple: false
        ]
      ],
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
            help: "Specify the ID (slug) for the post (without date format).",
            parser: :string,
            required: true
          ]
        ] ++ Cli.get_infile_options(),
      flags: Cli.get_verbosity_options()
    ]
  end

  @impl Lambdapad.Cli.Command
  def get_name, do: :"new-post"

  @impl Lambdapad.Cli.Command
  def command(%{name: name, infile: lambdapad_file, rawargs: rawargs} = params) do
    workdir = Cli.cwd!(lambdapad_file)

    Application.put_env(:lambdapad, :workdir, workdir)
    Application.put_env(:lambdapad, :loglevel, params[:loglevel])

    gt = Cli.print_level1("Reading configuration", lambdapad_file)

    t = Cli.print_level2("Compiling", lambdapad_file)
    {:ok, mod} = Blog.Base.compile(lambdapad_file)
    Cli.print_level2_ok()

    {:ok, config} = Config.init(Blog.Base.get_configs(mod, rawargs), workdir)

    interactive? = params[:interactive]

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
        System.halt(@user_interrupt_code)

      _otherwise ->
        IO.puts("cannot understand input")
        get(kind, true, name, default)
    end
  end
end
