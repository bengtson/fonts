defmodule Fonts.Tables.Hmtx do

  def glyph_metrics_for_index(index,font) do
    horiz_metrics_table = font["Tables"]["hmtx"]["Horizontal Metrics Table"]
    offset = index * 4
    <<
      _ :: binary-size(offset),
      advance_width :: unsigned-integer-size(16),
      left_side_bearing :: signed-integer-size(16),
      rest :: binary
    >> = horiz_metrics_table
#    IO.inspect left_side_bearing
    { advance_width, left_side_bearing }
  end

  def parse_table(checksum,offset,length,state) do

    # Needs hhea and maxp Tables
    table_map = state["Font"]["Tables"]
    hhea_table = table_map["hhea"]
    maxp_table = table_map["maxp"]
    cond do
      hhea_table == nil ->
        IO.puts "'hmtx' : Skipping - Wait For 'hhea'"
        {:skip}
      maxp_table == nil ->
        IO.puts "'hmtx' : Skipping - Wait For 'maxp'"
        {:skip}
      true ->
        gen_table(checksum,offset,length,state)
    end
  end

  def gen_table(checksum,offset,length,state) do
    IO.puts "'hmtx'" <> " : Parsing"

    %{"Binary" => binary, "Parser" => parser, "Font" => font} = state

    # Get number of h metrics
    # Get number of Glyphs
    num_h_metrics = font["Tables"]["hhea"]["Number Of H Metrics"]
    num_glyphs = font["Tables"]["maxp"]["Number Of Glyphs"]
    metrics_size = num_h_metrics * 4
    glyphs_size = (num_glyphs - num_h_metrics) * 2

    <<
      _ :: binary-size(offset),
      long_hor_metric :: binary-size(metrics_size),
      left_side_bearing :: binary-size(glyphs_size),
      rest :: binary
    >> = binary

    table = %{ "hmtx" => %{
      "Table Length" => length,
      "Table Offset" => offset,
      "Table Checksum" => checksum,
      "Horizontal Metrics Table" => long_hor_metric,
      "Left Side Bearing Table" => left_side_bearing
    }}
    %{"Tables" => tables} = font
    tables = Map.merge(tables,table)
    state = put_in(state, ["Font", "Tables"], tables)

    { :ok, state }
  end
end
