defmodule Blocked.Checker do
  @issue ~r{#?(\d+)}
  @repo_issue ~r{[\w-]+[#/]\d+}
  @owner_repo_issue ~r{([\w-]+)/([\w-]+)[#/](\d+)}
  @remote_url ~r{(?:https://github.com/([\w-]+)/([\w-]+).git)|(?:git@github.com:([\w-]+)/([\w-]+).git)}

  def get_current_repo do
    repo = %Git.Repository{path: "./"}
    with {:error, _} <- Git.remote(repo, ["get-url", "upstream"]),
         {:error, _} <- Git.remote(repo, ["get-url", "origin"]) do
      {:error, :not_found}
    else
      {:ok, result_url} ->
        result_url
        |> String.trim_trailing
        |> parse_remote_url
    end
  end

  defp parse_remote_url(str) do
    captures =
      Regex.run(@remote_url, str)
      |> Enum.map(fn x -> if x == "" do nil else x end end)
    {Enum.at(captures, 1) || Enum.at(captures, 3), Enum.at(captures, 2) || Enum.at(captures, 4)}
  end
end
