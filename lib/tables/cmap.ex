defmodule Fonts.Tables.Cmap do
  @doc """
  Takes a utf-8 glyph and the font map and returns the index of the glyph into the
  hmtx (horizontal metrics table). This is needed to determine string width.

  Calls function glyph_index to get the 16 bit unsiged index for the glyphs in the
  htmx table.
  """
  def glyph_indexes(glyphs, font) do
    # Find a Table ID that has Platform ID of 0. This seems to be the industry
    # standard ID to use.
    tables =
      font["Tables"]["cmap"]["Encoding Tables"]
      |> Enum.filter(fn {_, t} -> t["Platform ID"] == 0 end)

    table =
      case tables |> Enum.count() do
        0 -> raise("'cmap' table with 'Platform ID' of 1 not found.")
        _ -> tables |> Enum.at(0) |> elem(1)
      end

    subtable_map = table["Subtable Map"]
    subtable_format = subtable_map["Subtable Format"]

    glyphs |> Enum.map(&glyph_index(&1, subtable_map, subtable_format))
  end

  # Handles the subtype 4 glyph indexing.
  # glyph is the codepoint(?), table is the format 4 table.
  # Format 4 works like this ...
  #
  defp glyph_index(glyph, table, 4) do
    utf16_code = :unicode.characters_to_binary(glyph, :utf8, :utf16)
    <<utf16_integer::unsigned-integer-size(16)>> = utf16_code
    lut = table["Glyph Lookup Table"]

    lut_entry_number =
      lut
      |> Enum.find_index(fn {endval, _, _, _} -> utf16_integer <= endval end)

    lut_entry = Enum.at(lut, lut_entry_number)

    {lut_entry, lut_entry_number}
    |> gen_subtype_4_glyph_index(utf16_integer, table)
  end

  # Handles the subtype 6 glyph indexing.
  defp glyph_index(char, table, 6) do
    array = table["Glyph Index Array"]
    first = table["First Code"]
    offset = (char - first) * 2
    <<_::binary-size(offset), index::unsigned-integer-size(16), _::binary>> = array
    index
  end

  # Handles the subtype 12 glyph indexing.
  # glyph is the codepoint(?), table is the format 12 table.
  defp glyph_index(glyph, table, 12) do
    # Convert codepoint to 32 bit utf integer.
    utf32_code = :unicode.characters_to_binary(glyph, :utf8, :utf32)
    <<utf32_integer::unsigned-integer-size(32)>> = utf32_code

    # Find the entry for this code range and nil if not found.
    entry =
      table["Glyph Lookup Table"]
      |> Enum.find(fn {startcode, endcode, _} ->
        utf32_integer >= startcode and utf32_integer <= endcode
      end)

    # Handle no entry by returning 0 else calculate the index.
    case entry do
      nil ->
        0

      _ ->
        {_, _, start_glyph_code} = entry
        start_glyph_code + utf32_integer
    end
  end

  # Catches any unimplemented indexing subtypes.
  defp glyph_index(glyph, table, type) do
    raise(
      "Unhandled glyph table for, glyph: #{inspect(glyph)}, table: #{inspect(table)}, type: #{
        inspect(type)
      }"
    )
  end

  # Sub-Table helpers.
  # So the 'Offset' mode for type 4 is bizarre. The spec is confusing too. The parameters
  # provided for sub-type 4 give initial values for specific search and index generate
  # algorithm, none of which is used here.
  # If the deltaID is 0, then the offset provided is the bytes from the lut_entry to the
  # index number of the glyph which is in the Glyph Look Up Table which follows the ID Range
  # Offset Array.
  #
  # So the bytes count from the first byte in the Offset Array to the end of the Offset
  # array need to be subtracted from the Offset provided.
  defp gen_subtype_4_glyph_index({{_endcode, startcode, 0, off}, index}, glyph, table) do
    if glyph < startcode do
      0
    else
      off_table_length = table["Segment Count x2"]
      off_table_entry = index * 2
      glyph_array_byte = off - (off_table_length - off_table_entry) + 2 * (glyph - startcode)

      <<
        _skip::binary-size(glyph_array_byte),
        i::unsigned-integer-size(16),
        _rest::binary
      >> = table["Glyph ID Array"]

      i
    end
  end

  defp gen_subtype_4_glyph_index({{_endcode, startcode, delta, 0}, _index}, glyph, _table) do
    if glyph < startcode do
      0
    else
      rem(glyph + delta, 65536)
    end
  end

  # -- Parsing Code Below --

  @doc """
  Parses the 'cmap' table when loading the font.
  """
  def parse_table(checksum, offset, length, state) do
    %{"Binary" => binary, "Font" => font} = state

    <<
      _::binary-size(offset),
      table_version::unsigned-integer-size(16),
      number_tables::unsigned-integer-size(16),
      _rest::binary
    >> = binary

    # Get the sub-tables in the cmap.
    encoding_maps = get_format_tables(number_tables, offset, binary)

    table = %{
      "cmap" => %{
        "Table Length" => length,
        "Table Offset" => offset,
        "Table Checksum" => checksum,
        "Table Version" => Integer.to_string(table_version),
        "Number Of Tables" => number_tables,
        "Encoding Tables" => encoding_maps
      }
    }

    %{"Tables" => tables} = font
    tables = Map.merge(tables, table)
    state = put_in(state, ["Font", "Tables"], tables)

    {:ok, state}
  end

  def get_format_tables(format_count, table_start, binary) do
    get_format_table(format_count, table_start, 4, binary, %{})
  end

  def get_format_table(0, _, _, _, encoding_maps) do
    encoding_maps
  end

  def get_format_table(format_count, table_start, offset, binary, encoding_maps) do
    t = table_start + offset
    table_id = format_count

    <<
      _::binary-size(t),
      platform_id::unsigned-integer-size(16),
      encoding_id::unsigned-integer-size(16),
      subtable_offset::unsigned-integer-size(32),
      _::binary
    >> = binary

    subtable_offset = table_start + subtable_offset

    #    t_num = 3-format_count
    #    s_offset = offset+subtable_offset+4*t_num
    <<
      _::binary-size(subtable_offset),
      format::unsigned-integer-size(16),
      rest::binary
    >> = binary

    subtable_map = get_subtable(format, rest)

    encoding_map = %{
      "Table ID #{table_id}" => %{
        "Platform ID" => platform_id,
        "Encoding ID" => encoding_id,
        "Subtable Offset" => subtable_offset,
        "Subtable Map" => subtable_map
      }
    }

    encoding_maps = Map.merge(encoding_maps, encoding_map)

    get_format_table(format_count - 1, table_start, offset + 8, binary, encoding_maps)
  end

  defp get_subtable(4, table_data) do
    <<
      length::unsigned-integer-size(16),
      language::unsigned-integer-size(16),
      segcountx2::unsigned-integer-size(16),
      table_rest::binary
    >> = table_data

    segcount = div(segcountx2, 2)

    <<
      searchrange::unsigned-integer-size(16),
      entryselector::unsigned-integer-size(16),
      rangeshift::unsigned-integer-size(16),
      endcount::binary-size(segcount)-unit(16),
      0::unsigned-integer-size(16),
      startcount::binary-size(segcount)-unit(16),
      iddelta::binary-size(segcount)-unit(16),
      idrangeoffset::binary-size(segcount)-unit(16),
      glyphidarray::binary
    >> = table_rest

    # Build table for easy access. This merges each of the different arrays
    # into a tuple with {endval, startval, iddelta, idrangeoffset}
    e = for <<val::unsigned-integer-size(16) <- endcount>>, into: [], do: val
    s = for <<val::unsigned-integer-size(16) <- startcount>>, into: [], do: val
    d = for <<val::unsigned-integer-size(16) <- iddelta>>, into: [], do: val
    o = for <<val::unsigned-integer-size(16) <- idrangeoffset>>, into: [], do: val
    lut = Enum.zip([e, s, d, o])

    %{
      "Subtable Format" => 4,
      "Length" => length,
      "Language" => language,
      "Segment Count x2" => segcountx2,
      "Search Range" => searchrange,
      "Entry Selector" => entryselector,
      "Range Shift" => rangeshift,
      "End Count Array" => endcount,
      "Start Count Array" => startcount,
      "ID Delta Array" => iddelta,
      "ID Range Offset Array" => idrangeoffset,
      "Glyph ID Array" => glyphidarray,
      "Glyph Lookup Table" => lut
    }
  end

  defp get_subtable(6, table_data) do
    <<
      length::unsigned-integer-size(16),
      language::unsigned-integer-size(16),
      firstcode::unsigned-integer-size(16),
      entrycount::unsigned-integer-size(16),
      glypharray::binary-size(entrycount)-unit(16),
      _rest::binary
    >> = table_data

    %{
      "Subtable Format" => 6,
      "Length" => length,
      "Language" => language,
      "First Code" => firstcode,
      "Entry Count" => entrycount,
      "Glyph Index Array" => glypharray
    }
  end

  defp get_subtable(12, table_data) do
    <<
      _fill::unsigned-integer-size(16),
      length::unsigned-integer-size(32),
      language::unsigned-integer-size(32),
      numgroups::unsigned-integer-size(32),
      rest::binary
    >> = table_data

    groupsize = 12 * numgroups

    <<
      groups::binary-size(groupsize),
      glypharray::binary
    >> = rest

    lut =
      for <<
            startcharcode::unsigned-integer-size(32),
            endcharcode::unsigned-integer-size(32),
            startglyphcode::unsigned-integer-size(32) <- groups
          >>,
          into: [],
          do: {startcharcode, endcharcode, startglyphcode}

    tdata = %{
      "Subtable Format" => 12,
      "Length" => length,
      "Language" => language,
      "Group Count" => numgroups,
      "Groups" => groups,
      "Glyph Index Array" => glypharray,
      "Glyph Lookup Table" => lut
    }

    tdata
  end

  defp get_subtable(subtable_type, _table_data) do
    IO.inspect("Unhandled Glyph Table Type: #{subtable_type}")
  end
end
