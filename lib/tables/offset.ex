defmodule Fonts.Tables.Offset do
  def get_offset_table(state) do
    %{"Binary" => binary, "Parser" => parser, "Font" => font} = state
    %{"Cursor" => cursor} = parser
    %{"Tables" => tables} = font

    <<
      snft_version::binary-size(4),
      table_count::unsigned-integer-size(16),
      search_range::unsigned-integer-size(16),
      entry_selector::unsigned-integer-size(16),
      range_shift::unsigned-integer-size(16),
      _rest::binary
    >> = binary

    parser = Map.merge(parser, %{"Cursor" => cursor + 12})

    table = %{
      "offset" => %{
        "Offset Version" => snft_version,
        "Table Count" => table_count,
        "Search Range" => search_range,
        "Entry Selector" => entry_selector,
        "Range Shift" => range_shift
      }
    }

    tables = Map.merge(tables, table)
    font = put_in(font, ["Tables"], tables)
    %{"Binary" => binary, "Parser" => parser, "Font" => font}
  end
end
