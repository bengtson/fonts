defmodule Fonts.Metrics.StringWidth do
  @doc """
  Returns the width of the provided string and for the provided font for 1 em. Width in points can be calculated by muptipling by the point size.
  """
  def string_width(fontkey, string, points_size) do
    font_entry = Fonts.FontServer.entry(fontkey)
    font = font_entry["Font"]
    units_per_em = font["Tables"]["head"]["Units Per Em"]

    # - Get list of glyphid's
    # - Get list of glyph metrics.
    # - Calculate string width
    glyph_design_units =
      string
      |> String.codepoints()
      |> Fonts.Tables.Cmap.glyph_indexes(font)
      |> Enum.map(&Fonts.Tables.Hmtx.glyph_metrics_for_index(&1, font))
      |> calc_string_width(true, 0)

    glyph_design_units / units_per_em * points_size
  end

  # Following does not remove the right side bearing from the last glphy in
  # the string. Looked at using xmin, xmax to calculate rsb but it did
  # not work.

  # Called from the pipe to start the string width calculation. Parameters
  # for the set of calls are:
  #   list to process
  #   true if first call
  #   calculated width

  # Handles a nil list returning 0 width.
  # defp calc_string_width([], _, true, _) do
  #   0
  # end

  # Handles a list with only a single element. Calculates width.
  defp calc_string_width([{advance_width, left_side_bearing} | []], true, _) do
    advance_width - left_side_bearing
  end

  # Handles first element when there is more than one element.
  defp calc_string_width([{advance_width, left_side_bearing} | tail], true, _) do
    calc_string_width(tail, false, advance_width - left_side_bearing)
  end

  # Handles the last element in the list. Must preceed 'middle'
  defp calc_string_width([{advance_width, _left_side_bearing} | []], false, width) do
    width + advance_width
  end

  # Handles all middle elements in the list.
  defp calc_string_width([{advance_width, _} | tail], false, width) do
    calc_string_width(tail, false, width + advance_width)
  end
end
