defmodule Blocked.Checker do
  @moduledoc false


  @issue ~r{^#?(\d+)$}
  @repo_issue ~r{^([\w-]+)[#/](\d+)$}
  @owner_repo_issue ~r{^([\w-]+)/([\w-]+)[#/](\d+)$}
  @issue_url ~r{^https?://github.com/([\w-]+)/([\w-]+)/issues[#/](\d+)}
  @remote_url ~r{(?:https://github.com/([\w-]+)/([\w-]+).git)|(?:git@github.com:([\w-]+)/([\w-]+).git)}

  defmodule IssueReference do
    defstruct [:owner, :repo, :issue]
  end

  def check(issue_reference, config) do
    with {:ok, info = %IssueReference{}} <- parse_issue_reference(issue_reference, config) do
      Blocked.Checker.GithubBackend.check(info.owner, info.repo, info.issue, config)
    end
  end

  def get_current_repo_info(config) do
    if config.project_repo && config.project_owner do
      {:ok, {config.project_owner, config.project_repo}}
    else
      repo = %Git.Repository{path: "./"}
      with {:error, _} <- Git.remote(repo, ["get-url", "upstream"]),
           {:error, _} <- Git.remote(repo, ["get-url", "origin"]) do
        {:error, :repo_info}
      else
        {:ok, result_url} ->
          {owner, repo} =
          result_url
          |> String.trim_trailing
          |> parse_remote_url
        {:ok, {config.project_owner || owner, config.project_repo || repo}}
      end
    end
  end

  defp parse_remote_url(str) do
    captures =
      Regex.run(@remote_url, str)
      |> Enum.map(fn x -> if x == "" do nil else x end end)
    {Enum.at(captures, 1) || Enum.at(captures, 3), Enum.at(captures, 2) || Enum.at(captures, 4)}
  end

  def parse_issue_reference(issue_reference, config) do
    with nil <- Regex.run(@issue_url, issue_reference),
         nil <- Regex.run(@owner_repo_issue, issue_reference),
         nil <- Regex.run(@repo_issue, issue_reference),
         nil <- Regex.run(@issue, issue_reference) do
      {:error, :issue_parsing}
    else
      [_, issue] ->
        with {:ok, {owner, repo}} <- get_current_repo_info(config) do
          {:ok, %IssueReference{owner: owner, repo: repo, issue: issue}}
        end
      [_, repo, issue] ->
        with {:ok, {owner, _repo}} <- get_current_repo_info(config) do
          {:ok, %IssueReference{owner: owner, repo: repo, issue: issue}}
        end
      [_, owner, repo, issue] ->
        {:ok, %IssueReference{owner: owner, repo: repo, issue: issue}}
      _other ->
        {:error, :issue_parsing}
    end
  end
end
