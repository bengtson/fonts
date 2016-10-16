defmodule Fonts.Server do
  use GenServer
  @moduledoc """
  This is a genserver that loads bible layout information. This information can be queried for books, chapters in a book and verses in a chapter.

  The information about the books in the bible are held in a map. Each book has it's own entry with the key being the name of the book. The value of each entry is the info about the book in a binary as follows:

    byte 1 : "N" or "O" for new or old testament.
    byte 2 : Order of book in their respective testaments.
    byte 3 : Order of book in the Bible.
    byte 4 : Number of chapters in the book.
    byte 5..n : Number of verses starting with chapter 1. Each is a byte.

  """

  @doc """
  Starts the GenServer.
  """
  def start_link do
    {:ok, _} = GenServer.start_link(__MODULE__, :ok, [name: FontServer])
  end

  @doc """
  State for the BibleServer consists of the following:

    %{ "Metadata" => bible_metadata,
       "Verse Count" => verse_counter }

  bible_metadata : This is the map described above.
  verse_counter : Used to count all verses in the bible. Each book gets starting and ending verses set in the metadata.
  """
  def init (:ok) do
    state = load_font "/Users/bengm0ra/Projects/FileliF/Elixir/fonts/MinionPro-Regular.otf"

    {:ok, state}
  end

  @doc """
  Returns the number of chapters in the book specified.
  """
  def get_state do
    GenServer.call(FontServer, :state)
  end

  @doc """
  """
  def string_width(fontname, string) do
    GenServer.call(FontServer, {:string_width, fontname, string})
  end

  # Retrieves the chapter count for the specified book.
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:string_width, fontname, string}, _from, state) do
    width = Fonts.Metrics.StringWidth.stringwidth(state["Font"], fontname, string)
    {:reply, width, state}
  end

  # ----------------

  def load_font(font_path) do
    case File.read(font_path) do
      {:ok, binary} ->
        state = %{
          "Binary" => binary,
          "Parser" => %{
            "Cursor" => 0,
            "Table Read List" => []
          },
          "Font" => %{
            "Tables" => %{}
          }
        }
        state
          |> Fonts.Tables.Offset.get_offset_table
          |> Fonts.Tables.Tables.get_table_list
          |> Fonts.Tables.Tables.parse_tables
#          |> IO.inspect
      _ ->
        IO.puts "Couldn't open #{font_path}"
    end
  end

end
