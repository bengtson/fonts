defmodule FontsTest do
  use ExUnit.Case
  doctest Fonts

  test "Load Two Fonts" do
    font1 = "/Library/Fonts/MinionPro-Regular.otf"
    font2 = "/Library/Fonts/SourceSansPro-Regular.otf"
    font3 = "/Users/bengm0ra/Library/Fonts/OpenSans-Regular.ttf"
    Fonts.FontServer.load_font font1
    Fonts.FontServer.load_font font2
    Fonts.FontServer.load_font font3
    font_count = Enum.count(Fonts.FontServer.get_font_list)
    assert font_count == 3
  end

  test "Get Font Server State" do
    font1 = "/Library/Fonts/MinionPro-Regular.otf"
    Fonts.FontServer.load_font font1
    state = Fonts.FontServer.get_state
#    IO.inspect state
  end

  test "String Width Test" do
    width = Fonts.string_width("MinionPro-Regular", "Tack Så Mycket : The quick brown fox jumped over the lazy dog.", 12.0)
    assert width >= 314
    assert width <= 315
  end
end
