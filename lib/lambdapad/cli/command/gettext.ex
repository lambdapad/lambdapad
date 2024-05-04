defmodule Lambdapad.Cli.Command.Gettext do
  @moduledoc """
  Gettext is a module that help us to extract all of the translations
  from the templates and generate the .pot files that will be used
  to generate the .po files for the translations.
  """
  use Lambdapad.Cli.Command

  alias Expo.PO
  alias Gettext.Merger
  alias Lambdapad.{Blog, Cli, Config}
  alias Lambdapad.Generate.{Pages, Sources, Widgets}

  @default_language "en"
  @opts [fuzzy: false, fuzzy_threshold: 1.0]

  @impl Lambdapad.Cli.Command
  def options do
    [
      name: "gettext",
      about: "Extract all of the translations from templates",
      args: Cli.get_infile_options(),
      flags: Cli.get_verbosity_options()
    ]
  end

  @impl Lambdapad.Cli.Command
  def command(%{infile: filename, verbosity: loglevel, rawargs: rawargs}) do
    workdir = Cli.cwd!(filename)

    Application.put_env(:lambdapad, :workdir, workdir)
    Application.put_env(:lambdapad, :loglevel, loglevel)
    Sources.init()

    gt = Cli.print_level1("Reading configuration", filename)

    _ = Cli.print_level2("Compiling", filename)
    {:ok, mod} = Blog.Base.compile(filename)
    Cli.print_level2_ok()

    {:ok, config} = Config.init(Blog.Base.get_configs(mod, rawargs), workdir)
    Cli.print_level1_ok(gt)

    languages_path = config["blog"]["languages_path"]

    t = Cli.print_level1("Generate translations")
    Cli.print_level2("generate POT files in", languages_path)
    {:ok, _} = Application.ensure_all_started(:gettext)
    pot_files = extract(mod, config, workdir, languages_path)
    run_message_extraction(pot_files)
    Cli.print_level2_ok()

    Cli.print_level2("generate PO files")
    locales = config["blog"]["languages"] || [@default_language]
    gettext_config = []

    merge_messages_dir(languages_path, locales, @opts, gettext_config)
    |> Enum.each(fn {locale, file_stats} ->
      Enum.each(file_stats, fn {file, stats} ->
        Cli.print_level3("Generated #{locale} #{file} #{format_stats(stats)}")
      end)
    end)

    Cli.print_level2_ok()
    Cli.print_level1_ok(t)

    Sources.terminate()
    :ok = Cli.done(gt)
  end

  defp extract(mod, config, workdir, languages_path) do
    Gettext.Extractor.enable()
    Lambdapad.Gettext.compile(languages_path)
    _ = Widgets.compile_resources(Blog.Base.get_widgets(mod, config), workdir)
    _ = Pages.compile_resources(Blog.Base.get_pages(mod, config), workdir)
    Gettext.Extractor.pot_files(:lambdapad, [])
  after
    Gettext.Extractor.disable()
  end

  defp run_message_extraction(pot_files) do
    Enum.each(pot_files, fn {path, contents} ->
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, contents)
      Cli.print_level3("Extracted #{Path.relative_to_cwd(path)}")
    end)
  end

  defp merge_messages_dir(pot_dir, locales, opts, gettext_config) do
    for locale <- locales do
      po_dir = Path.join([pot_dir, locale, "LC_MESSAGES"])
      {locale, merge_dirs(po_dir, pot_dir, locale, opts, gettext_config)}
    end
  end

  defp merge_dirs(po_dir, pot_dir, locale, opts, gettext_config) do
    merger = fn pot_file ->
      po_file = find_matching_po(pot_file, po_dir)
      {contents, stats} = merge_or_create(pot_file, po_file, locale, opts, gettext_config)
      write_file(po_file, contents, stats)
    end

    pot_dir
    |> Path.join("*.pot")
    |> Path.wildcard()
    |> Task.async_stream(merger, ordered: false, timeout: :infinity)
    |> Enum.map(fn {:ok, data} -> data end)
  end

  defp find_matching_po(pot_file, po_dir) do
    domain = Path.basename(pot_file, ".pot")
    Path.join(po_dir, "#{domain}.po")
  end

  defp merge_or_create(pot_file, po_file, locale, opts, gettext_config) do
    {new_po, stats} =
      if File.regular?(po_file) do
        Merger.merge(
          PO.parse_file!(po_file),
          PO.parse_file!(pot_file),
          locale,
          opts,
          gettext_config
        )
      else
        Merger.new_po_file(po_file, pot_file, locale, opts)
      end

    {new_po
     |> Merger.prune_references(gettext_config)
     |> PO.compose(), stats}
  end

  defp write_file(path, contents, stats) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
    {path, stats}
  end

  defp format_stats(stats) do
    pluralized = if stats.new == 1, do: "message", else: "messages"

    "#{stats.new} new #{pluralized}, #{stats.removed} removed, " <>
      "#{stats.exact_matches} unchanged, #{stats.fuzzy_matches} reworded (fuzzy), " <>
      "#{stats.marked_as_obsolete} marked as obsolete"
  end
end
