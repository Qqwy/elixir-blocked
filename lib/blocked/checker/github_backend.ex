defmodule Blocked.Checker.GithubBackend do
  def check(owner_name, repo_name, issue_number) do
    case Tentacat.Issues.find(make_client(), owner_name, repo_name, issue_number) do
      {200, %{"closed_at" => nil}, _} ->
        {:ok, :issue_open}
      {200, %{"closed_at" => datetime_str}, _} when is_binary(datetime_str) ->
        {:ok, {:issue_closed, datetime_str}}
      {response_code, _, _} ->
        {:error, {:lookup_error, response_code}}
    end
  end

  # TODO allow configuration for authorized clients.
  # TODO cache client for repeated checks.
  def make_client() do
    Tentacat.Client.new()
  end
end
