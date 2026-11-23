#!/usr/bin/env elixir
Mix.install([
  {:resvg, "~> 0.5"}
])

defmodule Lambdapad.OgImage do
  @moduledoc """
  Generates dynamic OpenGraph (1200x630) and X/Twitter (800x418) card SVGs and PNGs
  for Lambdapad blog posts.
  """

  @months ~w(January February March April May June July August September October November December)

  # 4 gradient schemes {id, from_color, to_color}, diagonal top-left -> bottom-right.
  # Selected deterministically per post id so og:image visuals are distinct and stable.
  @gradients [
    {"slate-sky", "#0F172A", "#0284C7"},
    {"indigo-sky", "#1E1B4B", "#0EA5E9"},
    {"navy-teal", "#0F172A", "#0D9488"},
    {"violet-blue", "#311042", "#1D4ED8"}
  ]

  @og %{
    w: 1200,
    h: 630,
    padding: 80,
    logo_w: 190,
    logo_h: 54,
    logo_x: 930,
    logo_y: 36,
    title_top: 125,
    title_bottom: 435,
    font_sizes: [{72, 90}, {62, 78}, {52, 66}, {44, 56}],
    separator_y: 475,
    separator_x2: 880,
    date_y: 525,
    date_size: 28,
    meta_y: 568,
    meta_size: 22,
    featured_size: 180,
    featured_x: 945,
    featured_y: 410
  }

  @x %{
    w: 800,
    h: 418,
    padding: 54,
    logo_w: 130,
    logo_h: 38,
    logo_x: 616,
    logo_y: 24,
    title_top: 86,
    title_bottom: 290,
    font_sizes: [{48, 60}, {42, 52}, {36, 45}, {30, 38}],
    separator_y: 315,
    separator_x2: 585,
    date_y: 348,
    date_size: 19,
    meta_y: 378,
    meta_size: 15,
    featured_size: 120,
    featured_x: 630,
    featured_y: 272
  }

  def generate_og(post, images_dir), do: generate(post, images_dir, @og)
  def generate_x(post, images_dir), do: generate(post, images_dir, @x)

  defp generate(post, images_dir, cfg) do
    featured = encode_file(Path.join(images_dir, "notepad.png"), "image/png")
    date = format_date(post["date"], post["type"])
    meta = format_meta(post)
    title_text = post["title"] || "Lambdapad"
    gradient = pick_gradient(post["id"] || "default")

    {font_size, line_height, lines} = fit_title(title_text, cfg)
    first_y = title_first_y(lines, font_size, line_height, cfg)

    render_svg(featured, lines, font_size, line_height, first_y, date, meta, gradient, cfg)
  end

  defp pick_gradient(slug) do
    idx = :erlang.phash2(slug, length(@gradients))
    Enum.at(@gradients, idx)
  end

  defp encode_file(path, mime) do
    if File.exists?(path) do
      "data:#{mime};base64,#{Base.encode64(File.read!(path))}"
    else
      nil
    end
  end

  # Pick the largest font size where the title fits in <= 4 lines.
  defp fit_title(text, cfg) do
    {fs, lh} =
      Enum.find(cfg.font_sizes, List.last(cfg.font_sizes), fn {fs, _lh} ->
        length(wrap_text(text, chars_per_line(fs, cfg))) <= 4
      end)

    {fs, lh, wrap_text(text, chars_per_line(fs, cfg))}
  end

  defp chars_per_line(font_size, cfg) do
    avail = cfg.w - 2 * cfg.padding
    floor(avail / (font_size * 0.56))
  end

  defp wrap_text(text, max_chars) do
    {lines, last} =
      text
      |> String.split(~r/\s+/)
      |> Enum.reduce({[], ""}, fn word, {lines, current} ->
        candidate = if current == "", do: word, else: "#{current} #{word}"

        if String.length(candidate) > max_chars,
          do: {[current | lines], word},
          else: {lines, candidate}
      end)

    Enum.reverse(if last != "", do: [last | lines], else: lines)
  end

  defp title_first_y(lines, font_size, line_height, cfg) do
    n = length(lines)
    center_y = div(cfg.title_top + cfg.title_bottom, 2)
    block_h = font_size + (n - 1) * line_height
    center_y - div(block_h, 2) + round(font_size * 0.75)
  end

  defp render_tspans([first | rest], x, y, lh) do
    first_span = ~s(<tspan x="#{x}" y="#{y}">#{escape(first)}</tspan>)

    rest_spans =
      Enum.map_join(rest, "", fn line ->
        ~s(<tspan x="#{x}" dy="#{lh}">#{escape(line)}</tspan>)
      end)

    first_span <> rest_spans
  end

  defp escape(text) do
    text
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp format_date(iso_date, category) when is_binary(iso_date) do
    base =
      case Date.from_iso8601(String.trim(iso_date)) do
        {:ok, %Date{year: y, month: m, day: d}} ->
          "#{Enum.at(@months, m - 1)} #{d}, #{y}"

        _ ->
          iso_date
      end

    if is_binary(category) and category != "" do
      "#{base}  ·  #{category}"
    else
      base
    end
  end

  defp format_date(_, _), do: ""

  defp format_meta(_post), do: "lambdapad.com/blog"

  defp render_svg(featured, lines, font_size, line_height, first_y, date, meta, {grad_id, c1, c2}, cfg) do
    featured_tag =
      if featured do
        ~s(<image href="#{featured}" x="#{cfg.featured_x}" y="#{cfg.featured_y}" width="#{cfg.featured_size}" height="#{cfg.featured_size}" preserveAspectRatio="xMidYMid meet"/>)
      else
        ""
      end

    """
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="#{cfg.w}" height="#{cfg.h}" viewBox="0 0 #{cfg.w} #{cfg.h}">
      <defs>
        <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#{c1}"/>
          <stop offset="100%" stop-color="#{c2}"/>
        </linearGradient>
      </defs>
      <g id="#{grad_id}">
        <rect width="#{cfg.w}" height="#{cfg.h}" fill="url(#grad)"/>
        <text x="#{cfg.padding}" y="#{cfg.logo_y + div(cfg.logo_h, 2) + 8}" font-family="Arial, Helvetica, Liberation Sans, DejaVu Sans, Ubuntu, sans-serif" font-size="#{cfg.meta_size}" font-weight="bold" fill="#38BDF8" letter-spacing="2">LAMBDAPAD BLOG</text>
        <text font-family="Arial, Helvetica, Liberation Sans, DejaVu Sans, Ubuntu, sans-serif" font-size="#{font_size}" font-weight="bold" fill="white">#{render_tspans(lines, cfg.padding, first_y, line_height)}</text>
        <line x1="#{cfg.padding}" y1="#{cfg.separator_y}" x2="#{cfg.separator_x2}" y2="#{cfg.separator_y}" stroke="white" stroke-opacity="0.45" stroke-width="2"/>
        <text x="#{cfg.padding}" y="#{cfg.date_y}" font-family="Arial, Helvetica, Liberation Sans, DejaVu Sans, Ubuntu, sans-serif" font-size="#{cfg.date_size}" fill="white" fill-opacity="0.9">#{escape(date)}</text>
        <text x="#{cfg.padding}" y="#{cfg.meta_y}" font-family="Arial, Helvetica, Liberation Sans, DejaVu Sans, Ubuntu, sans-serif" font-size="#{cfg.meta_size}" font-weight="bold" fill="#38BDF8">#{escape(meta)}</text>
        #{featured_tag}
      </g>
    </svg>
    """
  end

  def parse_post_headers(md_file) do
    content = File.read!(md_file)
    [header_block | _] = String.split(content, ~r/\n\n/, parts: 2)

    header_block
    |> String.split("\n", trim: true)
    |> Enum.reduce(%{}, fn line, acc ->
      case String.split(line, ":", parts: 2) do
        [k, v] -> Map.put(acc, String.trim(k), String.trim(v))
        _ -> acc
      end
    end)
  end
end

web_dir = __DIR__
images_dir = Path.join([web_dir, "assets", "images"])
og_dir = Path.join(images_dir, "og")
x_dir = Path.join(images_dir, "x")

File.mkdir_p!(og_dir)
File.mkdir_p!(x_dir)

posts = Path.wildcard(Path.join([web_dir, "posts", "**", "*.md"]))

resvg_opts = [
  resources_dir: "/tmp",
  font_family: "DejaVu Sans",
  sans_serif_family: "DejaVu Sans"
]

{:ok, fonts} = Resvg.list_fonts(resvg_opts)
IO.puts("Resvg loaded #{length(fonts)} system font faces")

Enum.each(posts, fn post_file ->
  post = Lambdapad.OgImage.parse_post_headers(post_file)
  id = post["id"] || Path.basename(post_file, ".md")

  og_svg = Lambdapad.OgImage.generate_og(post, images_dir)
  {:ok, og_png} = Resvg.svg_string_to_png_buffer(og_svg, resvg_opts)
  og_png_path = Path.join(og_dir, "#{id}.png")
  File.write!(og_png_path, og_png)

  x_svg = Lambdapad.OgImage.generate_x(post, images_dir)
  {:ok, x_png} = Resvg.svg_string_to_png_buffer(x_svg, resvg_opts)
  x_png_path = Path.join(x_dir, "#{id}.png")
  File.write!(x_png_path, x_png)

  IO.puts("Generated OG & X cards for #{id}: #{og_png_path} (#{:erlang.iolist_size(og_png)} bytes), #{x_png_path} (#{:erlang.iolist_size(x_png)} bytes)")
end)

static_cards = [
  %{
    "id" => "blog",
    "title" => "Lambdapad Blog: Releases, Architecture & Guides",
    "type" => "Updates & Articles",
    "date" => "lambdapad.com/blog"
  },
  %{
    "id" => "default",
    "title" => "Lambdapad: Static Website Generator on the BEAM",
    "type" => "Elixir & Erlang",
    "date" => "lambdapad.com"
  }
]

Enum.each(static_cards, fn card ->
  id = card["id"]

  og_svg = Lambdapad.OgImage.generate_og(card, images_dir)
  {:ok, og_png} = Resvg.svg_string_to_png_buffer(og_svg, resvg_opts)
  File.write!(Path.join(og_dir, "#{id}.png"), og_png)

  x_svg = Lambdapad.OgImage.generate_x(card, images_dir)
  {:ok, x_png} = Resvg.svg_string_to_png_buffer(x_svg, resvg_opts)
  File.write!(Path.join(x_dir, "#{id}.png"), x_png)

  IO.puts("Generated OG & X cards for #{id}")
end)
