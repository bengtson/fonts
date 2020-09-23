defmodule Fonts.Tables.Name do
  def parse_table(checksum, offset, length, state) do
    #    IO.puts "'name'" <> " : Parsing"
    %{"Binary" => binary, "Parser" => parser, "Font" => font} = state

    <<
      _::binary-size(offset),
      format::unsigned-integer-size(16),
      count::unsigned-integer-size(16),
      stringoffset::unsigned-integer-size(16),
      rest::binary
    >> = binary

    # Get the sub-tables in the cmap.
    # encoding_maps = get_format_tables(number_tables, offset, binary)

    # table = %{
    #   "name" => %{
    #     "Format" => format,
    #     "Records" => count,
    #     "String Offset" => stringoffset
    #     # "Table Length" => length,
    #     # "Table Offset" => offset,
    #     # "Table Checksum" => checksum,
    #     # "Table Version" => Integer.to_string(table_version),
    #     # "Number Of Tables" => number_tables,
    #     # "Encoding Tables" => encoding_maps
    #   }
    # }

    recordsize = count * 12

    <<
      records::binary-size(recordsize),
      names::binary
    >> = rest

    recordlist =
      for <<
            platformid::unsigned-integer-size(16),
            platformspecificid::unsigned-integer-size(16),
            languageid::unsigned-integer-size(16),
            nameid::unsigned-integer-size(16),
            length::unsigned-integer-size(16),
            stringoffset::unsigned-integer-size(16) <-
              records
          >>,
          into: [],
          do: %{
            "Platform ID" => platformid,
            "Platform Specific ID" => platformspecificid,
            "Language ID" => languageid,
            "Name ID" => nameid,
            "Length" => length,
            "Offset" => stringoffset
          }

    recordlist =
      recordlist
      |> Enum.map(fn r -> {r, extract_name(r, names)} end)
      |> Enum.map(fn {r, name} -> Map.put(r, "Name", name) end)

    table = %{
      "name" => %{
        "Format" => format,
        "Records" => count,
        "String Offset" => stringoffset,
        "Name Records" => recordlist
        # "Table Length" => length,
        # "Table Offset" => offset,
        # "Table Checksum" => checksum,
        # "Table Version" => Integer.to_string(table_version),
        # "Number Of Tables" => number_tables,
        # "Encoding Tables" => encoding_maps
      }
    }

    %{"Tables" => tables} = font
    tables = Map.merge(tables, table)
    state = put_in(state, ["Font", "Tables"], tables)

    {:ok, state}
  end

  defp extract_name(record, nameheap) do
    offset = record["Offset"]
    length = record["Length"]
    plat_id = record["Platform ID"]
    spec_id = record["Platform Specific ID"]

    <<
      _skip::binary-size(offset),
      namebin::binary-size(length),
      _rest::binary
    >> = nameheap

    name_to_utf8(namebin, plat_id, spec_id)
  end

  defp name_to_utf8(namebin, 1, 0) do
    namebin
  end

  defp name_to_utf8(namebin, 3, 1) do
    :unicode.characters_to_binary(namebin, :utf16, :utf8)
  end
end
