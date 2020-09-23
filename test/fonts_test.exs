defmodule FontsTest do
  use ExUnit.Case
  doctest Fonts

  # test "Load Two Fonts" do
  #   font1 = "/Users/bengm0ra/Library/Fonts/MinionPro-Regular.otf"
  #   font2 = "/Users/bengm0ra/Library/Fonts/SourceSansPro-Regular.ttf"
  #   font3 = "/Library/Fonts/Georgia.ttf"
  #   #    font3 = "/System/Library/Fonts/Helvetica.ttf"
  #   Fonts.FontServer.load(font1)
  #   Fonts.FontServer.load(font2)
  #   Fonts.FontServer.load(font3)
  #   font_count = Enum.count(Fonts.FontServer.list())
  #   assert font_count == 3
  # end

  # test "Get Font Server State" do
  #   font1 = "/Library/Fonts/MinionPro-Regular.otf"
  #   Fonts.FontServer.load(font1)
  #   state = Fonts.FontServer.state()
  #   #    IO.inspect state
  # end

  test "String Width Test - MinionPro-Regular" do
    font1 = "/Library/Fonts/MinionPro-Regular.otf"
    Fonts.FontServer.load(font1)

    width =
      Fonts.string_width(
        {"Minion Pro", "Regular"},
        "Tack Så Mycket : The quick brown fox jumped over the lazy dog.",
        12.0
      )

    assert width >= 314
    assert width <= 315
  end

  # test "String Width Test - SourceSansPro" do
  #   font1 = "/Users/bengm0ra/Library/Fonts/SourceSansPro-Regular.ttf"
  #   Fonts.FontServer.load(font1)

  #   width =
  #     Fonts.string_width(
  #       {"Source Sans Pro", "Regular"},
  #       "Tack Så Mycket : The quick brown fox jumped over the lazy dog.",
  #       12.0
  #     )

  #   assert width >= 314
  #   assert width <= 315
  # end
end
