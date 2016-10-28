defmodule Fonts.Tables.Cmap do

  def glyph_indexes(glyphs,font) do
    # Following for testing only. Need to find a way to get a preferred table.
    glyph_table = font["Tables"]["cmap"]["Encoding Tables"]["Table ID 2"]["Subtable Map"]
    subtable_format = glyph_table["Subtable Format"]
    indexes = glyphs
      |> Enum.map(&(glyph_index_for_char(&1,glyph_table,subtable_format)))
    indexes
  end

  def parse_table(checksum,offset,length,state) do
#    IO.puts "'cmap'" <> " : Parsing"

    %{"Binary" => binary, "Parser" => parser, "Font" => font} = state
    <<
      _ :: binary-size(offset),
      table_version :: unsigned-integer-size(16),
      number_tables :: unsigned-integer-size(16),
      rest :: binary
    >> = binary

    # Get the sub-tables in the cmap.
    encoding_maps = get_format_tables(number_tables, offset, binary)

    table = %{ "cmap" => %{
      "Table Length" => length,
      "Table Offset" => offset,
      "Table Checksum" => checksum,
      "Table Version" => Integer.to_string(table_version),
      "Number Of Tables" => number_tables,
      "Encoding Tables" => encoding_maps
    }}



    %{"Tables" => tables} = font
    tables = Map.merge(tables,table)
    state = put_in(state, ["Font", "Tables"], tables)

    { :ok, state }
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
      _ :: binary-size(t),
      platform_id :: unsigned-integer-size(16),
      encoding_id :: unsigned-integer-size(16),
      subtable_offset :: unsigned-integer-size(32),
      _ :: binary
    >> = binary

    subtable_offset = table_start+subtable_offset

#    t_num = 3-format_count
#    s_offset = offset+subtable_offset+4*t_num
    <<
      _ :: binary-size(subtable_offset),
      format :: unsigned-integer-size(16),
      rest :: binary
    >> = binary

    subtable_map = get_subtable(format,rest)

    encoding_map = %{ "Table ID #{table_id}" =>  %{
      "Platform ID" => platform_id,
                     "Encoding ID" => encoding_id,
                     "Subtable Offset" => subtable_offset,
                     "Subtable Map" => subtable_map}}
    encoding_maps = Map.merge(encoding_maps,encoding_map)



    get_format_table(format_count-1, table_start, offset+8, binary, encoding_maps)
  end

  defp get_subtable(4,table_data) do
    <<
      length :: unsigned-integer-size(16),
      language :: unsigned-integer-size(16),
      segcountx2 :: unsigned-integer-size(16),
      table_rest :: binary
    >> = table_data
    segcount = div(segcountx2,2)
    <<
      searchrange :: unsigned-integer-size(16),
      entryselector :: unsigned-integer-size(16),
      rangeshift :: unsigned-integer-size(16),
      endcount :: binary-size(segcount)-unit(16),
      0 :: unsigned-integer-size(16),
      startcount :: binary-size(segcount)-unit(16),
      iddelta :: binary-size(segcount)-unit(16),
      idrangeoffset :: binary-size(segcount)-unit(16),
      glyphidarray :: binary
    >> = table_rest

    subtable_map = %{ "Subtable Format" => 4,
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

  defp glyph_index_for_char(char,table,6) do
#    IO.puts "Subtable 6: Looking Up Char: #{char}"
    array = table["Glyph Index Array"]
    first = table["First Code"]
    offset = (char-first) * 2
    <<     _ :: binary-size(offset),
       index :: unsigned-integer-size(16),
           _ :: binary >> = array
    index
  end

  defp get_subtable(6,table_data) do
    <<
      length :: unsigned-integer-size(16),
      language :: unsigned-integer-size(16),
      firstcode :: unsigned-integer-size(16),
      entrycount :: unsigned-integer-size(16),
      glypharray :: binary-size(entrycount)-unit(16),
      rest :: binary
    >> = table_data

    %{ "Subtable Format" => 6,
       "Length" => length,
       "Language" => language,
       "First Code" => firstcode,
       "Entry Count" => entrycount,
       "Glyph Index Array" => glypharray }
  end

end
