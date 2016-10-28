defmodule Fonts.Tables.Name do

  def parse_table(checksum,offset,length,state) do
#    IO.puts "'name'" <> " : Parsing"
    %{"Binary" => binary, "Parser" => parser, "Font" => font} = state
    <<
      _ :: binary-size(offset),
      format :: unsigned-integer-size(16),
      count :: unsigned-integer-size(16),
      rest :: binary
    >> = binary
#    IO.puts "Name Table Format #{format}"
#    IO.puts "Name Table Count #{count}"

    { :ok, state }
  end
end
