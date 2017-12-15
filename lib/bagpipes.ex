defmodule Bagpipes do
  @moduledoc """
  Documentation for Bagpipes.
  """


  @doc """
  Hello world.

  ## Examples

      iex> Bagpipes.hello
      :world

  """
  defmacro __using__(table) do
    quote do
      def search(term) do
        term
        |> String.replace(" ", "|")
        |> query
        |> search_result_to_struct
      end

      defp query(term) do
        table_str = unquote(table)
        Ecto.Adapters.SQL.query!(
          DiscworldQuotes.Repo,
          """
          SELECT * FROM #{table_str}
          WHERE id IN (
            SELECT searchable_id FROM #{table_str}_searches
            WHERE to_tsvector('english', searchable_field) @@ to_tsquery($1)
          );
          """,
          [term]
        )
      end

      defp search_result_to_struct(res) do
        cols = Enum.map res.columns, &(String.to_atom(&1))
        Enum.map(res.rows, fn(row) -> struct(__MODULE__, Enum.zip(cols, row)) end)
      end
    end
  end
end
