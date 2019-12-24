defmodule Create.MixProject do
  use Mix.Project

  def project do
    [
      app: :create,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:esqlite, "~> 0.4.0"},
      {:google_api_text_to_speech, "~> 0.7"},
      {:goth, "~> 1.2"}
    ]
  end
end
