defmodule Blocked do
  defmacro by(issue_reference) do
    do_by(issue_reference, nil, nil, nil)
  end

  defmacro by(issue_reference, kwargs) when is_list(kwargs) do
    do_by(issue_reference, nil, kwargs[:do], kwargs[:else])
  end

  defmacro by(issue_reference, reason, kwargs \\ []) when is_list(kwargs) do
    do_by(issue_reference, reason, kwargs[:do], kwargs[:else])
  end

  defp do_by(issue_reference, reason, hotfix_body, resolved_body) do
    # TODO do not run if we should not check
    config = Blocked.Config.load
    case Blocked.Checker.check(issue_reference, config) do
      {:ok, :issue_open} ->
        hotfix_body
      {:ok, {:issue_closed, closed_at}} ->
        show_closed_warning(issue_reference, reason, closed_at, config)
        hotfix_body || resolved_body
      {:error, error_info} ->
        show_check_error_warning(issue_reference, reason, error_info, config)
        # show_lookup_error_warning(issue_reference, reason, status_code, config)
        hotfix_body
    end
  end

  defp show_closed_warning(issue_reference, reason, closed_at, config) do
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

  defp show_lookup_error_warning(issue_reference, reason, response_code, config) do
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
