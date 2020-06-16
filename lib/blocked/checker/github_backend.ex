defmodule Blocked.Checker.GithubBackend do
  def check(owner_name, repo_name, issue_number, config) do
    case Tentacat.Issues.find(make_client(config), owner_name, repo_name, issue_number) do
      {200, %{"closed_at" => nil}, _} ->
        {:ok, :issue_open}
      {200, %{"closed_at" => datetime_str}, _} when is_binary(datetime_str) ->
        {:ok, {:issue_closed, datetime_str}}
      {response_code, _, _} ->
        {:error, {:lookup_error, response_code}}
    end
  end

  # TODO cache client for repeated checks.
  def make_client(config) do
    if config.github_api_token do
      Tentacat.Client.new(%{access_token: config.github_api_token})
    else
      Tentacat.Client.new()
    end
  end
end
