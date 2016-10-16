defmodule FontsTest do
  use ExUnit.Case
  doctest Fonts

  test "Show Font Map" do
    state = Fonts.Server.get_state
#    IO.inspect state
    assert 1 == 1
  end

  test "String Width Test" do
    width = Font.string_width("Times Roman", "Tack Så Mycket : The quick brown fox jumped over the lazy dog.")
    width = width * 12.0
    assert width >= 314
    assert width <= 315
  end
end
