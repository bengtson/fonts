defmodule Fonts.Tables.Head do

  def parse_table(checksum,offset,length,state) do
    IO.puts "'head'" <> " : Parsing"
    %{"Binary" => binary, "Parser" => parser, "Font" => font} = state
    <<
      _ :: binary-size(offset),
      table_version :: unsigned-integer-size(32),
      font_version :: unsigned-integer-size(32),
      checksum :: unsigned-integer-size(32),
      0x5F0F3CF5 :: unsigned-integer-size(32),
      flags :: unsigned-integer-size(16),
      units_per_em :: unsigned-integer-size(16),
      date_created :: integer-size(64),
      date_modified :: integer-size(64),
      x_min :: integer-size(16),
      y_min :: integer-size(16),
      x_max :: integer-size(16),
      y_max :: integer-size(16),
      mac_style :: unsigned-integer-size(16),
      lowest_rec_ppem :: unsigned-integer-size(16),
      direction_hint :: integer-size(16),
      index_to_loc_format :: integer-size(16),
      glyph_data_format :: integer-size(16),
      rest :: binary
    >> = binary

    table = %{ "head" => %{
      "Table Length" => length,
      "Table Offset" => offset,
      "Table Checksum" => checksum,
      "Table Version" =>
        Fonts.Tables.Tables.parse_version_number(table_version),
      "Font Version" => Fonts.Tables.Tables.parse_version_number(font_version),
      "Flags" => flags,
      "Units Per Em" => units_per_em,
      "Date Created" => date_created,
      "Date Modified" => date_modified,
      "X Minimum" => x_min,
      "Y Minimum" => y_min,
      "X Maximum" => x_max,
      "Y Maximum" => y_max,
      "Mac Style" => mac_style,
      "lowest_rec_ppem" => lowest_rec_ppem,
      "Direction Hint" => direction_hint,
      "index_to_loc_format" => index_to_loc_format,
      "Glyph Data Format" => glyph_data_format
    }}
    %{"Tables" => tables} = font
    tables = Map.merge(tables,table)
    state = put_in(state, ["Font", "Tables"], tables)
    { :ok, state }
  end
end
