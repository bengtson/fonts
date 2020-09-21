defmodule Fonts.Info do
  def info(fontname) do
    font = Fonts.FontServer.entry(fontname)
    IO.inspect(font, label: :font_entry)
  end
end
