defmodule FontsTest do
  use ExUnit.Case
  doctest Fonts

  test "Load Two Fonts" do
    font1 = "/Users/bengm0ra/Library/Fonts/MinionPro-Regular.otf"
    font2 = "/Users/bengm0ra/Library/Fonts/SourceSansPro-Regular.ttf"
    font3 = "/Library/Fonts/Georgia.ttf"
    #    font3 = "/System/Library/Fonts/Helvetica.ttf"
    Fonts.FontServer.load_font(font1)
    Fonts.FontServer.load_font(font2)
    Fonts.FontServer.load_font(font3)
    font_count = Enum.count(Fonts.FontServer.get_font_list())
    assert font_count == 3
  end

  test "Get Font Server State" do
    font1 = "/Library/Fonts/MinionPro-Regular.otf"
    Fonts.FontServer.load_font(font1)
    state = Fonts.FontServer.get_state()
    #    IO.inspect state
  end

  test "String Width Test - MinionPro-Regular" do
    font1 = "/Library/Fonts/MinionPro-Regular.otf"
    Fonts.FontServer.load_font(font1)

    width =
      Fonts.string_width(
        "MinionPro-Regular",
        "Tack Så Mycket : The quick brown fox jumped over the lazy dog.",
        12.0
      )

    assert width >= 314
    assert width <= 315
  end

  test "String Width Test - SourceSansPro" do
    font1 = "/Users/bengm0ra/Library/Fonts/SourceSansPro-Regular.ttf"
    Fonts.FontServer.load_font(font1)

    width =
      Fonts.string_width(
        "SourceSansPro-Regular",
        "Tack Så Mycket : The quick brown fox jumped over the lazy dog.",
        12.0
      )

    assert width >= 314
    assert width <= 315
  end
end
