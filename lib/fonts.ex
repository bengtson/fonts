defmodule Fonts do
  use Application

  def start( _type, _args ) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Fonts.Server, []),
    ]

    opts = [strategy: :one_for_one, name: Fonts.Supervisor]
    Supervisor.start_link(children, opts)

  end

end
