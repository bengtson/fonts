defmodule Fonts.Tables.Tables do
  def get_table_list(state) do
    table_count = state["Font"]["Tables"]["offset"]["Table Count"]
    get_table(table_count, state)
  end

  def get_table(0, state) do
    state
  end

  def get_table(table_count, state) do
    %{"Binary" => binary, "Parser" => parser, "Font" => font} = state
    %{"Cursor" => cursor, "Table Read List" => read_list} = parser

    <<
      _::binary-size(cursor),
      table_name::binary-size(4),
      _checksum::unsigned-integer-size(32),
      offset::unsigned-integer-size(32),
      length::unsigned-integer-size(32),
      _rest::binary
    >> = binary

    read_list = [{table_name, offset, length}] ++ read_list
    parser = Map.merge(parser, %{"Cursor" => cursor + 16, "Table Read List" => read_list})
    state = %{"Binary" => binary, "Parser" => parser, "Font" => font}
    get_table(table_count - 1, state)
  end

  def parse_tables(state) do
    %{"Parser" => parser} = state
    table_list = parser["Table Read List"]
    #    table_count = font["Tables"]["offset"]["Table Count"]
    parse_table(table_list, state)
  end

  def parse_table([], state) do
    state
  end

  def parse_table(table_list, state) do
    [x | tail] = table_list
    {table_name, offset, length} = x
    return = parse_table(table_name, 0, offset, length, state)

    case return do
      {:ok, state} -> parse_table(tail, state)
      {:skip} -> parse_table(tail ++ [x], state)
    end
  end

  def parse_table("cmap", checksum, offset, length, state) do
    Fonts.Tables.Cmap.parse_table(checksum, offset, length, state)
  end

  def parse_table("head", checksum, offset, length, state) do
    Fonts.Tables.Head.parse_table(checksum, offset, length, state)
  end

  def parse_table("hhea", checksum, offset, length, state) do
    Fonts.Tables.Hhea.parse_table(checksum, offset, length, state)
  end

  def parse_table("hmtx", checksum, offset, length, state) do
    Fonts.Tables.Hmtx.parse_table(checksum, offset, length, state)
  end

  def parse_table("maxp", checksum, offset, length, state) do
    Fonts.Tables.Maxp.parse_table(checksum, offset, length, state)
  end

  def parse_table("name", checksum, offset, length, state) do
    Fonts.Tables.Name.parse_table(checksum, offset, length, state)
  end

  def parse_table(_table_name, _checksum, _offset, _length, state) do
    #    IO.puts "'" <> table_name <> "'" <> " : Unknown Table Type"
    {:ok, state}
  end

  def parse_version_number(version) do
    version
    |> Integer.to_string(16)
    |> String.pad_leading(8, "0")
    |> String.split_at(4)
    |> Tuple.insert_at(1, ".")
    |> Tuple.to_list()
    |> Enum.join("")
  end
end
