# Bagpipes

Make beautiful squeaks with Elixir and 'pipes. Mostly, add Postgresql's full text search to an Ecto Schema.

**WARNING**: This is in _alpha_.

## Installation

The package can be installed by adding `bagpipes` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bagpipes, ">= 0.0.0", git: "git://github.com/mileszs/bagpipes.git"}
  ]
end
```

You will need to generate a migration. In that migration, you'll

1. Add an index for each field you want to search
2. Add a database view

After that, you'll add a single line to your Schema, and off you go!

### Indexes

For each field in your table that you want to search, you'll add an index like this:

```elixir
execute("CREATE INDEX index_quotes_on_value ON quotes USING gin(to_tsvector('english', value))")
```

In the above case, `value` is the name of the field, `quotes` is the name of the table.

### View

You'll create a view to make searching these fields easy. It will have a
section for each field you created an index for above, and will combine them
into one searchable field called `searchable_field`. (Very clever naming
scheme, eh?) Like this:

```elixir
execute("
  CREATE VIEW quotes_searches AS

  SELECT
    quotes.id AS searchable_id,
    'Quote' AS searchable_type,
    quotes.value AS searchable_field
  FROM quotes

  UNION

  SELECT
    quotes.id AS searchable_id,
    'Quote' AS searchable_type,
    quotes.source AS searchable_field
  FROM quotes
")
```

The above example has a table called `quotes`, and two fields. One field is
called `value`. The other is called `source`.

The finished migration would look like this:

```elixir
defmodule YourProject.Repo.Migrations.PlayThemBagpipes do
  use Ecto.Migration

  def up do
    execute("CREATE INDEX index_quotes_on_value ON quotes USING gin(to_tsvector('english', value))")
    execute("CREATE INDEX index_quotes_on_source ON quotes USING gin(to_tsvector('english', source))")

    execute("
      CREATE VIEW quotes_searches AS

      SELECT
        quotes.id AS searchable_id,
        'Quote' AS searchable_type,
        quotes.value AS searchable_field
      FROM quotes

      UNION

      SELECT
        quotes.id AS searchable_id,
        'Quote' AS searchable_type,
        quotes.source AS searchable_field
      FROM quotes
    ")
  end

  def down do
    execute("DROP INDEX index_quotes_on_value")
    execute("DROP INDEX index_quotes_on_source")
    execute("DROP VIEW quotes_searches")
  end
end
```

### Schema

Add the following line to the schema in which you need search:

```elixir
use Bagpipes
```

It might look like this now:

```elixir
defmodule YourProject.Quotes.Quote do
  use Ecto.Schema

  use Bagpipes

  import Ecto.Changeset
  alias YourProject.Quotes.Quote

  schema "quotes" do
    field :source, :string
    field :value, :string

    timestamps()
  end

  @doc false
  def changeset(%Quote{} = quote, attrs) do
    quote
    |> cast(attrs, [:value, :source])
    |> validate_required([:value, :source])
  end
end
```

## Usage

Any time you need to search one of your Schema, call the `search` function on your Ecto Schema, like so:

```elixir
YourProject.Quotes.Quote.search("bagpipes")
```

Boom! Oh, wait, bagpipes don't boom. Uh, majestic squeak!

## Roadmap

+ Provide a mix task for generating the migration
+ Oh, probably test stuff, right?
