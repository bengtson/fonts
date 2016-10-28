defmodule Fonts do
  use Application

  @doc """
  The font_name is the font's file name less leading path and trailing extention.
  """
  def string_width(font_name, string, points_size) do
    Fonts.Metrics.StringWidth.string_width(font_name, string, points_size)
  end

  def start( _type, _args ) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Fonts.FontServer, []),
    ]

    opts = [strategy: :one_for_one, name: Fonts.Supervisor]
    Supervisor.start_link(children, opts)

  end
end
