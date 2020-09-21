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

    IO.inspect(table, label: :selected_table_id)

    subtable_map = table["Subtable Map"]
    subtable_format = subtable_map["Subtable Format"]

    glyphs |> Enum.map(&glyph_index(&1, subtable_map, subtable_format))
  end

  # Handles the subtype 6 glyph indexing.
  defp glyph_index(char, table, 6) do
    #    IO.puts "Subtable 6: Looking Up Char: #{char}"
    array = table["Glyph Index Array"]
    first = table["First Code"]
    offset = (char - first) * 2
    <<_::binary-size(offset), index::unsigned-integer-size(16), _::binary>> = array
    index
  end

  # Catches any unimplemented indexing subtypes.
  defp glyph_index(glyph, table, type) do
    raise(
      "Unhandled glyph table for, glyph: #{inspect(glyph)}, table: #{inspect(table)}, type: #{
        inspect(type)
      }"
    )
  end

  # -- Parsing Code Below --

  @doc """
  Parses the 'cmap' table when loading the font.
  """
  def parse_table(checksum, offset, length, state) do
    IO.puts("'cmap'" <> " : Parsing")

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

    subtable_map = %{
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
      "Glyph ID Array" => glyphidarray
    }

    # Note that the glyphidarray needs a size. This can probably be calcluted
    # from the last entries in the access arrays. endcount-offset?

    subtable_map
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
    IO.inspect(table_data, label: :z2)

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

    tdata = %{
      "Subtable Format" => 12,
      "Length" => length,
      "Language" => language,
      "Group Count" => numgroups,
      "Groups" => groups,
      "Glyph Index Array" => glypharray
    }

    IO.inspect(tdata, label: :zz)
    tdata
  end

  defp get_subtable(subtable_type, _table_data) do
    IO.inspect("Unhandled Glyph Table Type: #{subtable_type}")
  end
end
