defmodule Fonts.Tables.Hhea do

  def parse_table(checksum,offset,length,state) do
    IO.puts "'hhea'" <> " : Parsing"

    %{"Binary" => binary, "Parser" => parser, "Font" => font} = state
    <<
      _ :: binary-size(offset),
      table_version_high :: integer-size(16),
      table_version_low :: integer-size(16),
      ascender :: integer-size(16),
      descender :: integer-size(16),
      line_gap :: integer-size(16),
      advance_width_max :: unsigned-integer-size(16),
      min_left_side_bearing :: integer-size(16),
      min_right_side_bearing :: integer-size(16),
      x_max_extent :: integer-size(16),
      caret_slope_rise :: integer-size(16),
      caret_slope_run :: integer-size(16),
      caret_offset :: integer-size(16),
      0 :: integer-size(16),
      0 :: integer-size(16),
      0 :: integer-size(16),
      0 :: integer-size(16),
      metric_data_format :: integer-size(16),
      number_of_h_metrics :: unsigned-integer-size(16),
      rest :: binary
    >> = binary

    table = %{ "hhea" => %{
      "Table Length" => length,
      "Table Offset" => offset,
      "Table Checksum" => checksum,
      "Table Version" => Integer.to_string(table_version_high) <> "." <>
          Integer.to_string(table_version_low),
      "Ascender" => ascender,
      "Descender" => descender,
      "Line Gap" => line_gap,
      "Advance Width Max" => advance_width_max,
      "Minimum Left Side Bearing" => min_left_side_bearing,
      "Minimum Right Side Bearing" => min_right_side_bearing,
      "X Max Extent" => x_max_extent,
      "Caret Slop Rise" => caret_slope_rise,
      "Caret Slope Run" => caret_slope_run,
      "Caret Offset" => caret_offset,
      "Metric Data Format" => metric_data_format,
      "Number Of H Metrics" => number_of_h_metrics
    }}
    %{"Tables" => tables} = font
    tables = Map.merge(tables,table)
    state = put_in(state, ["Font", "Tables"], tables)
    { :ok, state }
  end
end
