defmodule Blocked.CheckerTest do
  use ExUnit.Case
  alias Blocked.Checker.IssueReference

  def config() do
    %Blocked.Config{
      project_repo: "example",
      project_owner: "JohnDoe"
    }
  end

  # TODO this is a fine place for property-based tests
  describe "parse_issue_reference/2" do
    test "parses issue references" do
      assert {:ok, %IssueReference{repo: "example", issue: "10"}} = Blocked.Checker.parse_issue_reference("#10", config())
      assert {:ok, %IssueReference{repo: "example", issue: "42"}} = Blocked.Checker.parse_issue_reference("#42", config())
    end

    test "parses repo + issue references" do
      assert {:ok, %IssueReference{repo: "foo", issue: "10"}} = Blocked.Checker.parse_issue_reference("foo/10", config())
      assert {:ok, %IssueReference{repo: "bar", issue: "42"}} = Blocked.Checker.parse_issue_reference("bar#42", config())
    end

    test "parses owner/org + repo + issue references" do
      assert {:ok, %IssueReference{owner: "Jose", repo: "foo", issue: "10"}} = Blocked.Checker.parse_issue_reference("Jose/foo/10", config())
      assert {:ok, %IssueReference{owner: "Qqwy", repo: "bar", issue: "42"}} = Blocked.Checker.parse_issue_reference("Qqwy/bar#42", config())
    end

    test "parses full-blown github issue-URLs" do
      assert {:ok, %IssueReference{owner: "Jose", repo: "foo", issue: "10"}} = Blocked.Checker.parse_issue_reference("https://github.com/Jose/foo/issues/10", config())
      assert {:ok, %IssueReference{owner: "Qqwy", repo: "elixir-blocked", issue: "42"}} = Blocked.Checker.parse_issue_reference("http://github.com/Qqwy/elixir-blocked/issues/42", config())
    end
  end

  describe "get_current_repo_info/1" do
    test "reads info from configuration if proper fields are provided" do
      assert {:ok, {"JohnDoe", "example"}} = Blocked.Checker.get_current_repo_info(config())
    end

    test "reads info from local git repo configuration if one or both of the config fields are missing" do
      config = config()
      config = put_in(config.project_owner, nil)
      assert {:ok, {"Qqwy", "example"}} = Blocked.Checker.get_current_repo_info(config)

      config = config()
      config = put_in(config.project_repo, nil)
      assert {:ok, {"JohnDoe", "elixir-blocked"}} = Blocked.Checker.get_current_repo_info(config)

      config = config()
      config = put_in(config.project_repo, nil)
      config = put_in(config.project_owner, nil)
      assert {:ok, {"Qqwy", "elixir-blocked"}} = Blocked.Checker.get_current_repo_info(config)
    end
  end
end
