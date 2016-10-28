defmodule Fonts.FontServer do
  use GenServer
  @moduledoc """
  The FontStore holds information about available fonts. Some fonts may have been fully parsed while others may simply be 'noticed' in the system but not yet called for use.

  The Font Server will load fonts however, once loaded, the server is not longer needed for obtaining information about the font. For instance, 'string width' is handled without services from the font.

  State font server is shown:

    %{ "Font List => %{} }

  Each entry in the "Font List" is:

    %{ "Filename" => ..,
       "Fontname" => ..,
       "Binary" => ..,      # Font file data.
       "Font" => ..,        # Parsed font data.
       ... }

  """

  @doc """
  Starts the Font Server. This is started but will not have any fonts until one is loaded by the user.
  """
  def start_link do
    {:ok, _} = GenServer.start_link(__MODULE__, :ok, [name: FontServer])
  end

  @doc """
  Loads the font in the specified font file. If the font can be successfully loaded it will be added as a font available to the Font Server. If there is an error, the error message will be returned.
  """
  @spec load_font(String.t) :: { :ok, Map } | { :error, String.t }
  def load_font font_path do
    GenServer.call(FontServer, {:load, font_path})
  end

  @doc """
  Returns the entry for the font name speciied.
  """
  def get_font_entry(font_name) do
    GenServer.call(FontServer, {:entry, font_name})
  end

  @doc """
  Returns a list of the fonts that are loaded into the Font Server.
  """
  @spec get_font_list :: [ List ]
  def get_font_list do
    GenServer.call(FontServer, :list)
  end

  @doc """
  Returns the full state of the Font Server. This would generally be used only for diagnostic purposes.
  """
  @spec get_state :: { Map }
  def get_state do
    GenServer.call(FontServer, :state)
  end

  def handle_call({:entry, font_name}, _from, state) do
    entry = state["Font List"][font_name]
    {:reply, entry, state}
  end

  def handle_call({:load, font_path}, _from, state) do
    case font_loader font_path do
      {:ok, font} ->
        newf = Map.merge(state["Font List"],font)
#        IO.inspect newf
        state = put_in state["Font List"],newf
        {:reply, {:ok, font}, state}
      {:error, message} ->
        {:reply, {:error, message}, state}
    end
  end

  def handle_call(:list, _from, state) do
    list = state["Font List"]
    |> Map.keys
    {:reply, list, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  defp font_loader(font_path) do
    font_name = Path.rootname(Path.basename(font_path))
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
        x = font
          |> Fonts.Tables.Offset.get_offset_table
          |> Fonts.Tables.Tables.get_table_list
          |> Fonts.Tables.Tables.parse_tables
        x = Map.merge(x,%{"File Name" => font_path})
        {:ok, %{ font_name => x} }
#          |> IO.inspect
      _ ->
        {:error, "Couldn't open #{font_path}"}
    end
  end

  @doc """
  Called by the GenServer when it is started.
  """
  def init (:ok) do
    {:ok, %{ "Font List" => %{} } }
  end

end
