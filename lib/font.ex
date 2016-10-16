defmodule Font do

  def string_width(fontname, string) do
    Fonts.Server.string_width(fontname, string)
  end
end
