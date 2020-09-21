defmodule Fonts.FontServer do
  use GenServer

  @moduledoc """
  The FontStore holds information about available fonts. Some fonts may have been fully parsed while
  others may simply be 'noticed' in the system but not yet called for use.

  The Font Server will load fonts however, once loaded, the server is not longer needed for
  obtaining information about the font. For instance, 'string width' is handled without services
  from the font.

  Fonts are referenced with the server as {family, subfamily} for example ...
    {Source Sans Pro, Regular}
  This is referred to as 'fontkey'.
  """

  @doc """
  Starts the Font Server. This is started but will not have any fonts until one is loaded by the user.
  """
  def start_link do
    {:ok, _} = GenServer.start_link(__MODULE__, :ok, name: FontServer)
  end

  @doc """
  Loads the font in the specified font file. If the font can be successfully loaded it will be added as a font available to the Font Server. If there is an error, the error message will be returned.
  """
  def load(font_path) do
    GenServer.call(FontServer, {:load, font_path})
  end

  @doc """
  Removes the specified font from the server.
  """
  def remove(fontkey) do
    GenServer.call(FontServer, {:remove, fontkey})
  end

  def remove_all() do
    GenServer.call(FontServer, :remove_all)
  end

  @doc """
  Returns the entry for the font name speciied.
  """
  def entry(fontkey) do
    GenServer.call(FontServer, {:entry, fontkey})
  end

  @doc """
  Returns a list of the font keys that are loaded into the Font Server.
  """
  def list do
    GenServer.call(FontServer, :list)
  end

  @doc """
  Returns the full state of the Font Server. This would generally be used only for diagnostic purposes.
  """
  def state do
    GenServer.call(FontServer, :state)
  end

  def handle_call({:entry, fontkey}, _from, state) do
    entry = state.fonts[fontkey]
    {:reply, entry, state}
  end

  def handle_call({:load, font_path}, _from, state) do
    case font_loader(font_path) do
      {:ok, font} ->
        newf = Map.merge(state.fonts, font)
        #        IO.inspect(newf)
        state = put_in(state.fonts, newf)
        {:reply, {:ok, font}, state}

      {:error, message} ->
        {:reply, {:error, message}, state}
    end
  end

  def handle_call(:list, _from, state) do
    list =
      state.fonts
      |> Map.keys()

    {:reply, list, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:remove, fontkey}, _from, state) do
    fonts = Map.delete(state.fonts, fontkey)
    {:reply, :ok, %{state | fonts: fonts}}
  end

  def handle_call(:remove_all, _from, _state) do
    {:reply, :ok, %{fonts: %{}}}
  end

  # Given the path to the font file, this will load the specified font.
  defp font_loader(font_path) do
    case File.read(font_path) do
      {:ok, binary} ->
        font = %{
          "Binary" => binary,
          "Parser" => %{
            "Cursor" => 0,
            "Table Read List" => []
          },
          "Font" => %{
            "Tables" => %{}
          }
        }

        x =
          font
          |> Fonts.Tables.Offset.get_offset_table()
          |> Fonts.Tables.Tables.get_table_list()
          |> Fonts.Tables.Tables.parse_tables()

        fontkey = fontkey(x)
        x = Map.merge(x, %{"File Name" => font_path})
        x = Map.merge(x, %{"Font Key" => fontkey})

        IO.inspect(fontkey, label: :fontkey)
        {:ok, %{fontkey => x}}

      #          |> IO.inspect
      _ ->
        {:error, "Couldn't open #{font_path}"}
    end
  end

  # Given the decoded font, this generates the font key based on the
  # font family and subfamily.
  defp fontkey(font) do
    namerecords = font["Font"]["Tables"]["name"]["Name Records"]

    fontfamily =
      namerecords
      |> Enum.find(fn r -> r["Name ID"] == 1 end)
      |> Map.fetch!("Name")

    fontsubfamily =
      namerecords
      |> Enum.find(fn r -> r["Name ID"] == 2 end)
      |> Map.fetch!("Name")

    {fontfamily, fontsubfamily}
  end

  @doc """
  Called by the GenServer when it is started.
  """
  def init(:ok) do
    {:ok, %{fonts: %{}}}
  end
end
