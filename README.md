# Fonts

Provides various font services useful for text layout or generating text.

## services

The following services are planned and ordered according to their likely implementation:

- Font Metrics - given a string, will return the metrics for the string.

## Todo

- Handle loading of multiple fonts.
- Have prescreening of fonts in a directory.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `fonts` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:fonts, "~> 0.1.0"}]
    end
    ```

  2. Ensure `fonts` is started before your application:

    ```elixir
    def application do
      [applications: [:fonts]]
    end
    ```
