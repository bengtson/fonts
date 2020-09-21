defmodule Fonts.Test do
  require Logger

  def test() do
    Fonts.FontServer.remove_all()
    font1 = "/Users/bengm0ra/Library/Fonts/MinionPro-Regular.otf"
    font2 = "/Users/bengm0ra/Library/Fonts/SourceSansPro-Regular.ttf"
    font3 = "/Library/Fonts/Georgia.ttf"
    #    font3 = "/System/Library/Fonts/Helvetica.ttf"
    Fonts.FontServer.load(font1)
    Fonts.FontServer.load(font2)
    Fonts.FontServer.load(font3)
    font_count = Enum.count(Fonts.FontServer.list())
    Logger.info("Fonts Loaded: #{font_count}")
    # Fonts.Info.info("MinionPro-Regular")
    #  Fonts.Info.info("Georgia")
    # Fonts.Info.info("SourceSansPro-Regular")
  end

  def sw() do
    font1 = "/Users/bengm0ra/Library/Fonts/Georgia.ttf"
    Fonts.FontServer.load(font1)

    width =
      Fonts.string_width(
        #        {"Source Sans Pro", "Regular"},
        {"Georgia", "Regular"},
        "Tack Så Mycket : The quick brown fox jumped over the lazy dog.",
        12.0
      )

    IO.puts("String Width: #{width}, Expected: #{314.0}")
  end
end
