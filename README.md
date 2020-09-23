# Fonts

Provides various font services useful for text layout or generating text.

This is a framework that has been tested with a single font 'Minion Pro - Regular'. It will be expanded as new functionality is required or as new fonts are needed. The current code may work for other fonts but no testing has been done.

## Services

The following services are planned and ordered according to their likely implementation:

- Font Metrics - given a string, will return the metrics for the string.

## References

The following link is a good reference on the Open Type font format.

https://docs.microsoft.com/en-us/typography/opentype/spec/otff
https://developer.apple.com/fonts/TrueType-Reference-Manual/

## Complete
[x] Pickup info from Name table.
[x] Change font key from file name to {fontfamily, fontsubfamily}
[x] Get character width based on sub-table type 4.
[x] sub-table 'offset' selector not coded.
[x] Add load time for a font.
[x] Get character width based on sub-table type 12.

## Todo
[ ] Load collection font files ... files with multiple fonts.
[ ] Handle kerning entries.
[ ] Handle automatic loading or scanning of fonts on the system.

- Have prescreening of fonts in a directory.

## Commit Comments

- GenServer now stores fonts that have been loaded.


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `fonts` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:fonts, "~> 0.2.0"}]
    end
    ```

  2. Ensure `fonts` is started before your application:

    ```elixir
    def application do
      [applications: [:fonts]]
    end
    ```
