defmodule Blocked do
  @moduledoc """
  ## Usage

  1. Put `require Blocked` in your module to be able to use the exposed macro.
  2. Write `Blocked.by(issue_reference, reason, do: ..., else: ...)` wherever you have to apply a temporary fix.


      defmodule Foo do
        require Blocked

        def calc(x) do
          Blocked.by("some-repo/10", "Until a `pow` function exists, fall back to multiplication.") do
            x * x
          else
            pow(x, 2)
          end
        end
      end

  ## When will `Blocked.by` run?

  By default, the checks will only be performed inside Continuous Integration environments.
  (That is, any place where `System.get_env("CI")` is set).
  The reason for this default is that the checks perform HTTP requests to the GitHub-API,
  which will slow down compilation somewhat.

  This can be overridden by altering the `warn`-field in the `Blocked.Config` for a particular environment.

  ## What if I have a private GitHub-repository?

  By default, `Blocked` will run with an unauthenticated GitHub-client.
  You can configure the client by specifying an API token
  (of an account that has access to the repository in question)
  in the `Blocked.Config`.

  ## Supported Issue Reference patterns

  1. `123` or `#123`: issue number. Assumes that the isue is part of the current repository.
  2. `reponame/123` or `reponame#123`: repository + issue number. Assumes that the repository is part of the same owner/organization as the current repository.
  3. `owner/reponame/123` or `owner/reponame#123`: owner/organization name + repository + issue number.
  4. `https://github.com/owner/reponame/issues/123`: Full-blown URL to the page of the issue.

  ## Automatic Repository Detection

  We use the `git remote get-url` command to check for the remote URL of the current repository and attempt to extract the owner/organization and repository name from that.
  We check against the `upstream` remote (useful in a forked project), and the `origin` remote.

  If your setup is different, you can configure the repository and owner name by specifying custom settings in the `Blocked.Config`.
  """


  @doc """
  Prints a compile-time warning whenever the GitHub issue `issue_reference` is closed.

  This warning will contain the optional `reason`.

  When the issue is open, will expand to the (optional) `do: ...` block.
  This block can be used to indicate the code that is a 'temporary hotfix'.

  When the issue is closed, will expand to the (optional) `else: ...` block.
  This block can be used to indicate the desired ideal code that could be used
  once the hotfix is no longer necessary.

  If no `else: ...` is passed, we'll still expand to the `do: ...` block
  (since the hotfix should in that case work).

  See the module-documentation for more information on what format issue-references
  are supported, and on when `Blocked.by` is (and is not) run.

  ## Examples

   Only issue-reference

      Blocked.by("some-repo/10")

      Blocked.by("some-other-repo#10")


   Issue-reference and reason

      Blocked.by("some-repo/10", "We need a special fetching function to support this.")

   Issue-reference, wrapping code

      defmodule Foo do
        require Blocked

        def calc(x) do
        Blocked.by("some-repo/10", "Until a `pow` function exists, fall back to multiplication.") do
            x * x
          else
            pow(x, 2)
          end
        end
      end
  """
  @spec by(binary(), binary() | nil, [] | [do: do_block] | [do: do_block, else: do_block]) :: (do_block | else_block) when do_block: any, else_block: any
  defmacro by(issue_reference, reason \\ nil, code_blocks \\ [])

  # Runs when no reason is passed:
  defmacro by(issue_reference, kwargs, []) when is_list(kwargs) do
    issue_reference = compile_time_eval(issue_reference, __CALLER__)
    do_by(issue_reference, nil, kwargs[:do], kwargs[:else])
  end

  defmacro by(issue_reference, reason, kwargs) when is_list(kwargs) do
    issue_reference = compile_time_eval(issue_reference, __CALLER__)
    reason = compile_time_eval(reason, __CALLER__)
    do_by(issue_reference, reason, kwargs[:do], kwargs[:else])
  end

  defp do_by(issue_reference, reason, hotfix_body, resolved_body)
    when is_binary(issue_reference)
    and  (reason == nil or is_binary(reason))
    do
    config = cached_load_config()
    if !config.warn do
      hotfix_body
    else
      case Blocked.Checker.check(issue_reference, config) do
        {:ok, :issue_open} ->
          hotfix_body
        {:ok, {:issue_closed, closed_at}} ->
          show_closed_warning(issue_reference, reason, closed_at, config)
          resolved_body || hotfix_body
        {:error, error_info} ->
          show_check_error_warning(issue_reference, reason, error_info, config)
          hotfix_body
      end
    end
  end

    defp do_by(issue_reference, reason, _hotfix_body, _resolved_body) do
      raise(ArgumentError, """
      Improper usage of `Blocked.by`.
      Cannot parse issue_reference `#{inspect(issue_reference)}`
      and/or reason `#{inspect(reason)}`
      """)
    end

  # Cache configuration in the (compiling) process' dictionary
  # to keep compilation fast, especially when _not_ performing remote requests
  # (i.e. when config.warn is `false`).
  defp cached_load_config do
    case Process.get({__MODULE__, :config}) do
      config = %Blocked.Config{} ->
        config
      nil ->
        config = Blocked.Config.load_with_defaults
        Process.put({__MODULE__, :config}, config)
        config
    end
  end

  # In general `eval_quoted` is bad to be used.
  # In this case we need it however,
  # because we want to inspect the issue-reference string
  # and reason string
  # at compile-time
  # (regardless of whether they were e.g. passed as hard-coded string
  # or e.g. inside a module-attribute)
  defp compile_time_eval(quoted, env) do
    {result, []} = Code.eval_quoted(quoted, [], env)
    result
  end

  defp show_closed_warning(issue_reference, reason, closed_at, _config) do
    reason_str = if reason do "Reason for blocking: #{reason}" else "" end
    warn("""
    A blocking issue has been closed!
    Issue: #{issue_reference}
    #{reason_str}
    Closed at: #{closed_at}
    """)
  end

  @doc false
  def show_check_error_warning(issue_reference, reason, error_info, config) do
    case error_info do
      :issue_parsing ->
        warn("Cannot parse issue reference `#{issue_reference}`")
      :repo_info ->
        warn("Cannot ascertain the current project owner/organization and repository name, which are required to look up issue reference `#{issue_reference}`")
      {:lookup_error, response_code} ->
        show_lookup_error_warning(issue_reference, reason, response_code, config)
    end
  end

  defp show_lookup_error_warning(issue_reference, _reason, response_code, _config) do
    warn("""
    Could not look up the blocking issue `#{issue_reference}`.
    The lookup request returned the following HTTP status code: #{response_code}.

    Please make sure that the issue reference is correct,
    `Blocked` has been configured properly,
    and that you have a working internet connection.
    """)
  end

  @doc false
  def warn(string) do
    {:current_stacktrace, stacktrace} = Process.info(self(), :current_stacktrace)
    IO.warn("`Blocked.by`: " <> string <> "\n------------------------", Enum.drop(stacktrace, 3))
  end
end
