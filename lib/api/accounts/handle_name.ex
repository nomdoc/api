defmodule API.HandleName do
  @moduledoc false

  use API, :model

  schema "handle_name" do
    belongs_to :user, API.User
    belongs_to :organization, API.Organization
    field :value, :string
    timestamps()
  end

  @spec changeset(t(), data) :: Changeset.t() when data: %{value: binary()}
  def changeset(%__MODULE__{} = handle_name, data) do
    params = ~w(value)a

    handle_name
    |> cast(data, params)
    |> validate_required(params)
    |> unique_constraint(:value)
  end

  @adjectives [
    "amazing",
    "amusing",
    "artful",
    "beautiful",
    "blissful",
    "bold",
    "brave",
    "bright",
    "brilliant",
    "candid",
    "cheeky",
    "cute",
    "dear",
    "delightful",
    "determined",
    "diligent",
    "discreet",
    "driven",
    "earnest",
    "fair",
    "fantastic",
    "fearless",
    "focused",
    "generous",
    "happy",
    "humble",
    "intelligent",
    "little",
    "lively",
    "loving",
    "magical",
    "misty",
    "modest",
    "motivated",
    "nameless",
    "natural",
    "outgoing",
    "perfect",
    "polished",
    "polite",
    "proud",
    "quiet",
    "rational",
    "respected",
    "rich",
    "shining",
    "shy",
    "silent",
    "sincere",
    "skilled",
    "small",
    "smart",
    "snowy",
    "sparkling",
    "talented",
    "tasty",
    "unique",
    "warm",
    "wild",
    "wise",
    "wonderful",
    "worthy",
    "young",
    "yummy"
  ]

  @nouns [
    "bird",
    "breeze",
    "brook",
    "bush",
    "butterfly",
    "cherry",
    "cloud",
    "darkness",
    "dawn",
    "dew",
    "dream",
    "dust",
    "feather",
    "field",
    "fire",
    "firefly",
    "flower",
    "fog",
    "forest",
    "frog",
    "frost",
    "glade",
    "glitter",
    "grass",
    "haze",
    "hill",
    "lake",
    "leaf",
    "meadow",
    "moon",
    "morning",
    "mountain",
    "night",
    "paper",
    "pine",
    "pond",
    "rain",
    "resonance",
    "river",
    "sea",
    "shadow",
    "shape",
    "silence",
    "sky",
    "smoke",
    "snow",
    "snowflake",
    "sound",
    "star",
    "sun",
    "sun",
    "sunset",
    "surf",
    "thunder",
    "tree",
    "violet",
    "voice",
    "water",
    "water",
    "waterfall",
    "wave",
    "wildflower",
    "wind",
    "wood"
  ]

  @spec generate_value() :: binary()
  def generate_value() do
    [@adjectives, @nouns]
    |> Enum.map(fn names -> Enum.random(names) end)
    |> Enum.concat([Nanoid.generate(12, "abcdefghijklmnopqrstuvwxyz1234567890")])
    |> Enum.join("-")
  end
end
