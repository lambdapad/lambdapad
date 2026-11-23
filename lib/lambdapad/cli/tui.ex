defmodule Lambdapad.Cli.Tui do
  @moduledoc """
  Lightweight pure-Elixir terminal UI helpers for interactive CLI wizards.

  Requires Erlang/OTP 28+ (`:shell.start_interactive({:noshell, :raw})`) and
  an interactive TTY. Non-TTY environments and older OTP releases should fall
  back to standard line-based prompts or CLI flags.
  """

  @clear_to_end "\e[J"

  @doc """
  Returns the major Erlang/OTP release number of the running VM.
  """
  @spec otp_version() :: pos_integer()
  def otp_version do
    :erlang.system_info(:otp_release)
    |> List.to_integer()
  end

  @clear_to_end "\e[J"

  @doc """
  Returns `true` when standard I/O is attached to an interactive terminal.
  """
  @spec tty?() :: boolean()
  def tty? do
    match?({:ok, _}, :io.columns(:standard_io))
  end

  @clear_to_end "\e[J"

  @doc """
  Returns `true` when the Mini-TUI can run (OTP 28+ and interactive TTY).
  """
  @spec supported?() :: boolean()
  def supported? do
    otp_version() >= 28 and tty?()
  end

  @clear_to_end "\e[J"

  @doc """
  Converts a human-readable title into a URL-safe lowercase slug.
  """
  @spec slugify(String.t()) :: String.t()
  def slugify(title) when is_binary(title) do
    title
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end

  @clear_to_end "\e[J"

  @doc """
  Displays a styled header banner for the interactive wizard.
  """
  @spec banner(String.t(), String.t()) :: :ok
  def banner(title, subtitle) do
    IO.write([
      "\r\n",
      IO.ANSI.cyan(),
      IO.ANSI.bright(),
      "  ",
      title,
      IO.ANSI.reset(),
      "\r\n",
      IO.ANSI.faint(),
      "  ",
      subtitle,
      IO.ANSI.reset(),
      "\r\n\r\n"
    ])
  end

  @clear_to_end "\e[J"

  @doc """
  Prompts for a text value with an optional default and validation function.
  Returns `{:ok, value}` or `:cancel`.
  """
  @spec prompt_text(String.t(), keyword()) :: {:ok, String.t()} | :cancel
  def prompt_text(label, opts \\ []) do
    default = Keyword.get(opts, :default, "")

    state = %{
      label: label,
      default: default,
      hint: Keyword.get(opts, :hint),
      required?: Keyword.get(opts, :required, false),
      validator: Keyword.get(opts, :validator),
      error: nil,
      buffer: default,
      initial?: true
    }

    with_raw_mode(fn -> text_loop(state) end)
  end

  defp text_loop(state) do
    render_text_prompt(
      state.label,
      state.hint,
      state.error,
      state.buffer,
      state.initial? and state.default != ""
    )

    handle_text_key(read_key(), state)
  end

  defp handle_text_key(:ctrl_c, _state) do
    IO.write("\r\n")
    :cancel
  end

  defp handle_text_key(:esc, _state) do
    IO.write("\r\n")
    :cancel
  end

  defp handle_text_key(:enter, state), do: submit_text(state)

  defp handle_text_key(:backspace, state) do
    next_buf =
      if state.buffer == "",
        do: "",
        else: String.slice(state.buffer, 0, String.length(state.buffer) - 1)

    clear_text_prompt(state.hint, state.error)
    text_loop(%{state | error: nil, buffer: next_buf, initial?: false})
  end

  defp handle_text_key({:char, ch}, state) do
    next_buf = if state.initial?, do: ch, else: state.buffer <> ch
    clear_text_prompt(state.hint, state.error)
    text_loop(%{state | error: nil, buffer: next_buf, initial?: false})
  end

  defp handle_text_key(_other, state) do
    clear_text_prompt(state.hint, state.error)
    text_loop(state)
  end

  defp submit_text(state) do
    trimmed = String.trim(state.buffer)

    cond do
      state.required? and trimmed == "" ->
        clear_text_prompt(state.hint, nil)
        text_loop(%{state | error: "This field is required.", initial?: false})

      is_function(state.validator, 1) ->
        case state.validator.(trimmed) do
          :ok ->
            IO.write("\r\n")
            {:ok, trimmed}

          {:error, msg} ->
            clear_text_prompt(state.hint, nil)
            text_loop(%{state | error: msg, initial?: false})
        end

      true ->
        IO.write("\r\n")
        {:ok, trimmed}
    end
  end

  defp render_text_prompt(label, hint, error, buffer, default_active?) do
    hint_line =
      if hint do
        [IO.ANSI.faint(), "  ", hint, IO.ANSI.reset(), "\r\n"]
      else
        []
      end

    err_line =
      if error do
        [IO.ANSI.red(), "  ! ", error, IO.ANSI.reset(), "\r\n"]
      else
        []
      end

    val_style = if default_active?, do: IO.ANSI.faint(), else: IO.ANSI.reset()

    IO.write([
      IO.ANSI.cyan(),
      "  ? ",
      IO.ANSI.reset(),
      IO.ANSI.bright(),
      label,
      IO.ANSI.reset(),
      "\r\n",
      hint_line,
      err_line,
      "  ",
      IO.ANSI.cyan(),
      "› ",
      IO.ANSI.reset(),
      val_style,
      buffer,
      IO.ANSI.reset()
    ])
  end

  defp clear_text_prompt(hint, error) do
    lines_above = 1 + if(hint, do: 1, else: 0) + if(error, do: 1, else: 0)
    IO.write([IO.ANSI.cursor_up(lines_above), "\r", @clear_to_end])
  end

  @clear_to_end "\e[J"

  @doc """
  Prompts the user to pick an option from a list using Up/Down arrow keys.
  Each option can be `{label, value}` or a plain string.
  Returns `{:ok, value}` or `:cancel`.
  """
  @spec prompt_select(String.t(), [{String.t(), term()} | String.t()], keyword()) ::
          {:ok, term()} | :cancel
  def prompt_select(label, options, opts \\ []) when options != [] do
    hint = Keyword.get(opts, :hint, "Use ↑/↓ arrows and Enter to select")

    normalized =
      Enum.map(options, fn
        {text, val} -> {text, val}
        text -> {to_string(text), text}
      end)

    with_raw_mode(fn ->
      IO.write([
        IO.ANSI.cyan(),
        "  ? ",
        IO.ANSI.reset(),
        IO.ANSI.bright(),
        label,
        IO.ANSI.reset(),
        "\r\n",
        IO.ANSI.faint(),
        "  ",
        hint,
        IO.ANSI.reset(),
        "\r\n"
      ])

      select_loop(normalized, 0, false)
    end)
  end

  defp select_loop(options, idx, redraw?) do
    if redraw? do
      IO.write([IO.ANSI.cursor_up(max(length(options), 1)), "\r", @clear_to_end])
    end

    options
    |> Enum.with_index()
    |> Enum.each(fn {{text, _val}, i} -> render_select_item(text, i == idx) end)

    handle_select_key(read_key(), options, idx)
  end

  defp render_select_item(text, true) do
    IO.write(["  ", IO.ANSI.cyan(), IO.ANSI.bright(), "❯ ", text, IO.ANSI.reset(), "\r\n"])
  end

  defp render_select_item(text, false) do
    IO.write(["    ", IO.ANSI.faint(), text, IO.ANSI.reset(), "\r\n"])
  end

  defp handle_select_key(:ctrl_c, _options, _idx), do: :cancel
  defp handle_select_key(:esc, _options, _idx), do: :cancel

  defp handle_select_key(:enter, options, idx) do
    {_text, val} = Enum.at(options, idx)
    {:ok, val}
  end

  defp handle_select_key(:up, options, idx) do
    count = length(options)
    next_idx = if idx == 0, do: count - 1, else: idx - 1
    select_loop(options, next_idx, true)
  end

  defp handle_select_key(:down, options, idx) do
    count = length(options)
    next_idx = if idx == count - 1, do: 0, else: idx + 1
    select_loop(options, next_idx, true)
  end

  defp handle_select_key(_other, options, idx), do: select_loop(options, idx, true)

  @doc """
  Displays a bordered preview block before final confirmation.
  """
  @spec preview_box(String.t(), [String.t()]) :: :ok
  def preview_box(title, lines) do
    IO.write([
      "\r\n  ",
      IO.ANSI.cyan(),
      IO.ANSI.bright(),
      title,
      IO.ANSI.reset(),
      "\r\n",
      IO.ANSI.faint(),
      "  ────────────────────────────────────────────────────",
      IO.ANSI.reset(),
      "\r\n"
    ])

    Enum.each(lines, fn line ->
      IO.write(["  ", line, "\r\n"])
    end)

    IO.write([
      IO.ANSI.faint(),
      "  ────────────────────────────────────────────────────",
      IO.ANSI.reset(),
      "\r\n\r\n"
    ])
  end

  defp with_raw_mode(fun) do
    :shell.start_interactive({:noshell, :raw})

    try do
      fun.()
    after
      :shell.start_interactive({:noshell, :cooked})
    end
  end

  defp read_key do
    :standard_io
    |> :io.get_chars("", 1)
    |> decode_key()
  end

  defp decode_key(:eof), do: :ctrl_c
  defp decode_key({:error, _}), do: :ctrl_c
  defp decode_key(<<3>>), do: :ctrl_c
  defp decode_key("\r"), do: :enter
  defp decode_key("\n"), do: :enter
  defp decode_key(<<127>>), do: :backspace
  defp decode_key(<<8>>), do: :backspace
  defp decode_key(<<27>>), do: read_escape_sequence()
  defp decode_key(ch) when is_binary(ch), do: {:char, ch}
  defp decode_key(other) when is_list(other), do: {:char, List.to_string(other)}

  defp read_escape_sequence do
    # Only wait briefly for '[' so bare Esc returns quickly; since :io.get_chars
    # blocks in raw mode, read next char only if available via Task with short timeout.
    task = Task.async(fn -> :io.get_chars(:standard_io, "", 1) end)

    case Task.yield(task, 25) || Task.shutdown(task, :brutal_kill) do
      {:ok, "["} ->
        case :io.get_chars(:standard_io, "", 1) do
          "A" -> :up
          "B" -> :down
          "C" -> :right
          "D" -> :left
          _ -> :other
        end

      _ ->
        :esc
    end
  end
end
