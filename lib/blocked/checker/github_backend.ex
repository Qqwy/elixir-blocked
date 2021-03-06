defmodule Blocked.Checker.GithubBackend do
  @moduledoc false

  def check(owner_name, repo_name, issue_number, config) do
    {:ok, res} = __MODULE__.Caller.issue_info(owner_name, repo_name, issue_number, config)
    case {res.status, res.body, res} do
      {200, %{"closed_at" => nil}, _} ->
        {:ok, :issue_open}
      {200, %{"closed_at" => datetime_str}, _} when is_binary(datetime_str) ->
        {:ok, {:issue_closed, datetime_str}}
      {response_code, _, _} ->
        {:error, {:lookup_error, response_code}}
    end
  end

  defmodule Caller do
    use Tesla
    adapter Tesla.Adapter.Mint

    def issue_info(owner_name, repo_name, issue_number, config) do
      get(client(config), "/repos/#{owner_name}/#{repo_name}/issues/#{issue_number}")
    end

    def client(config) do
      middleware = [
        {Tesla.Middleware.BaseUrl, "https://api.github.com"},
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Headers, [{"User-agent", "elixir-blocked"}]}
      ] ++ if config.github_api_token do
        [{Tesla.Middleware.Headers, [{"Authorization", "token " <> config.github_api_token }]}]
      else
        []
      end

      Tesla.client(middleware)
    end
  end
end
