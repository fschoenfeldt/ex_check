defmodule ExCheck.JSON do
  @moduledoc false

  # Minimal JSON encoder for the fully-controlled output of the JSON/agent reporters.
  # Kept dependency-free on purpose: ex_check targets Elixir ~> 1.12 (no built-in
  # JSON module, that arrived in 1.18) and must not pull a runtime dep like Jason.

  @spec encode(term) :: iodata
  def encode(term), do: do_encode(term)

  defp do_encode(nil), do: "null"
  defp do_encode(true), do: "true"
  defp do_encode(false), do: "false"
  defp do_encode(int) when is_integer(int), do: Integer.to_string(int)
  defp do_encode(float) when is_float(float), do: Float.to_string(float)
  defp do_encode(atom) when is_atom(atom), do: encode_string(Atom.to_string(atom))
  defp do_encode(str) when is_binary(str), do: encode_string(str)

  defp do_encode(list) when is_list(list) do
    inner = list |> Enum.map(&do_encode/1) |> Enum.intersperse(",")
    ["[", inner, "]"]
  end

  defp do_encode(map) when is_map(map) do
    inner =
      map
      |> Enum.map(fn {key, value} -> [encode_key(key), ":", do_encode(value)] end)
      |> Enum.intersperse(",")

    ["{", inner, "}"]
  end

  defp encode_key(key) when is_atom(key), do: encode_string(Atom.to_string(key))
  defp encode_key(key) when is_binary(key), do: encode_string(key)

  defp encode_string(str) do
    [?", escape(str, ""), ?"]
  end

  defp escape(<<>>, acc), do: acc
  defp escape(<<?", rest::binary>>, acc), do: escape(rest, acc <> "\\\"")
  defp escape(<<?\\, rest::binary>>, acc), do: escape(rest, acc <> "\\\\")
  defp escape(<<?\n, rest::binary>>, acc), do: escape(rest, acc <> "\\n")
  defp escape(<<?\r, rest::binary>>, acc), do: escape(rest, acc <> "\\r")
  defp escape(<<?\t, rest::binary>>, acc), do: escape(rest, acc <> "\\t")
  defp escape(<<?\f, rest::binary>>, acc), do: escape(rest, acc <> "\\f")
  defp escape(<<?\b, rest::binary>>, acc), do: escape(rest, acc <> "\\b")

  defp escape(<<char::utf8, rest::binary>>, acc) when char < 0x20 do
    escaped = "\\u" <> (char |> Integer.to_string(16) |> String.pad_leading(4, "0"))
    escape(rest, acc <> escaped)
  end

  defp escape(<<char::utf8, rest::binary>>, acc) do
    escape(rest, acc <> <<char::utf8>>)
  end
end
