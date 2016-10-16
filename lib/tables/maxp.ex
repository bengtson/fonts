defmodule Fonts.Tables.Maxp do

  def parse_table(checksum,offset,length,state) do
    IO.puts "'maxp'" <> " : Parsing"

    %{"Binary" => binary, "Parser" => parser, "Font" => font} = state
    <<
      _ :: binary-size(offset),
      table_version :: unsigned-integer-size(32),
      rest :: binary
    >> = binary

    state = gen_table(table_version, checksum, offset, length, state)
    v = Fonts.Tables.Tables.parse_version_number table_version
    { :ok, state }
  end

  def gen_table(0x00005000, checksum, offset, length, state) do
    %{"Binary" => binary, "Parser" => parser, "Font" => font} = state
    <<
      _ :: binary-size(offset),
      table_version :: unsigned-integer-size(32),
      number_glyphs :: unsigned-integer-size(16),
      rest :: binary
    >> = binary

    table = %{ "maxp" => %{
      "Table Length" => length,
      "Table Offset" => offset,
      "Table Checksum" => checksum,
      "Table Version" =>
        Fonts.Tables.Tables.parse_version_number(table_version),
      "Number Of Glyphs" => number_glyphs,
    }}
    %{"Tables" => tables} = font
    tables = Map.merge(tables,table)
    state = put_in(state, ["Font", "Tables"], tables)
  end

  def gen_table(table_version, checksum, offset, length, state) do
    %{"Binary" => binary, "Parser" => parser, "Font" => font} = state
    <<
      _ :: binary-size(offset),
      table_version :: unsigned-integer-size(32),
      number_glyphs :: unsigned-integer-size(16),
      max_points :: unsigned-integer-size(16),
      max_contours :: unsigned-integer-size(16),
      max_composite_points :: unsigned-integer-size(16),
      max_composite_contours :: unsigned-integer-size(16),
      max_zones :: unsigned-integer-size(16),
      max_twilight_points :: unsigned-integer-size(16),
      max_storage :: unsigned-integer-size(16),
      max_function_defs :: unsigned-integer-size(16),
      max_instruction_defs :: unsigned-integer-size(16),
      max_stack_elements :: unsigned-integer-size(16),
      max_size_of_instructions :: unsigned-integer-size(16),
      max_component_elements :: unsigned-integer-size(16),
      max_component_depth :: unsigned-integer-size(16),
      rest :: binary
    >> = binary

    table = %{ "maxp" => %{
      "Table Length" => length,
      "Table Offset" => offset,
      "Table Checksum" => checksum,
      "Table Version" =>
        Fonts.Tables.Tables.parse_version_number(table_version),
      "Number Of Glyphs" => number_glyphs,
      "Maximum Points" => max_points,
      "Maximum Contours" => max_contours,
      "Maximum Composite Points" => max_composite_points,
      "Maximum Composite Contours" => max_composite_contours,
      "Maximum Zones" => max_zones,
      "Maximum Twilight Points" => max_twilight_points,
      "Maximum Storage" => max_storage,
      "Maximum Function Definitions" => max_function_defs,
      "Maximum Instruction Definitions" => max_instruction_defs,
      "Maximum Stack Elements" => max_stack_elements,
      "Maximum Size Of Instructions" => max_size_of_instructions,
      "Maximum Component Elements" => max_component_elements,
      "Maximum Component Depth" => max_component_depth
    }}
    %{"Tables" => tables} = font
    tables = Map.merge(tables,table)
    state = put_in(state, ["Font", "Tables"], tables)
  end
end
