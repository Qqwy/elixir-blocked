defmodule Blocked.Config do
  @moduledoc """
  Configuration for `Blocked`.

  The simplest ways to configure `Blocked` is by:

  - adding `config :blocked. [warn: true, project_owner: "YourName"]` to your Elixir configuration file.
    (for older Elixir versions, this is `Mix.Config`; for newer versions, `Config`.)
  - alternatively, adding system-environment-variables like `BLOCKED_WARN=true`, `BLOCKED_PROJECT_OWNER="YourName"` etc. to the environment you want to run `Blocked` in.

  If you want to check the configuration in the current environment,
  print the output of `Blocked.Config.load_with_defaults`.

  More advanced configuration set-ups are possible by using the advanced features of `Specify`.
  """
  require Specify
  Specify.defconfig(sources: [%Specify.Provider.MixEnv{application: :blocked, optional: true}, %Specify.Provider.SystemEnv{prefix: "BLOCKED", optional: true}]) do
    @doc """
    trigger warnings in this particular environment.

    When this is off, `Blocked.by` will simply silently compile
    to whatever block was passed.

    It is automatically turned on (by default)
    when we're in a Continuous Integration environment.
    (this is checked by looking for the prescence of the `CI` environment variable.)
    """
    field :warn, :term, default: nil

    @doc """
    The repository name of this source-code project.

    This can be overridden if you cannot or don't want to rely
    on `Blocked`'s auto-detection using the git command-line tools.
    """
    field :project_repo, :term, default: nil

    @doc """
    The name of the owner or organization of this source-code project.

    This can be overridden if you cannot or don't want to rely
    on `Blocked`'s auto-detection using the git command-line tools.
    """
    field :project_owner, :term, default: nil

    @doc """
    This needs to be set if (and only if) you have a private GitHub-project,
    because otherwise we cannot access its issues.

    The personal API token requires "repo" access.

    c.f. https://github.blog/2013-05-16-personal-api-tokens/
    """
    field :github_api_token, :term, default: nil
  end

  def load_with_defaults do
    config = load()
    if config.warn == nil && System.get_env("CI") do
      put_in(config.warn, true)
    else
      config
    end
  end
end
