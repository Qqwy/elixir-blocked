defmodule BlockedTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  doctest Blocked

  describe "Macro usage" do
    test "Integration test - happy path - issue still open (requires an internet connection)" do
      io = capture_io(:stderr, fn ->
        defmodule ExampleIssueOpen do
          def bar(x) do
            Blocked.by("elixir-blocked#1") do
              x * x
            else
              x * x * x
            end
          end
        end

        assert ExampleIssueOpen.bar(10) == 100
      end)

      assert(io == "")
    end

    test "Integration test - happy path - issue closed (requires an internet connection)" do
      io = capture_io(:stderr, fn ->
        defmodule ExampleIssueClosed do
          def bar(x) do
            Blocked.by("elixir-blocked#2") do
              x * x
            else
              x * x * x
            end
          end
        end

        assert ExampleIssueClosed.bar(10) == 1000
      end)

      assert(io =~ """
      \e[33mwarning: \e[0m`Blocked.by`: A blocking issue has been closed!
      Issue: elixir-blocked#2

      Closed at: 2020-06-16T21:07:41Z

      ------------------------
      """)

    end

    test "Integration test - happy path - issue closed (with reason) (requires an internet connection)" do
      io = capture_io(:stderr, fn ->
        defmodule ExampleIssueClosedWithReason do
          def bar(x) do
            Blocked.by("elixir-blocked#2", "We want to be able to do cool stuff!") do
              x * x
            end
          end
        end
      end)

      assert(io =~ """
      \e[33mwarning: \e[0m`Blocked.by`: A blocking issue has been closed!
      Issue: elixir-blocked#2
      Reason for blocking: We want to be able to do cool stuff!
      Closed at: 2020-06-16T21:07:41Z

      ------------------------
      """)
    end


    test "Integration test - sad path: non-existent issue (requires an internet connection)" do
      io = capture_io(:stderr, fn ->
        defmodule ExampleSad do
          def bar(x) do
            Blocked.by("elixir-blocked#0") do
              x * x
            end
          end
        end
      end)

      assert(io =~ """
      \e[33mwarning: \e[0m`Blocked.by`: Could not look up the blocking issue `elixir-blocked#0`.
      The lookup request returned the following HTTP status code: 404.

      Please make sure that the issue reference is correct,
      `Blocked` has been configured properly,
      and that you have a working internet connection.

      ------------------------
      """)
    end

    test "malformed issue reference" do
      io = capture_io(:stderr, fn ->
        defmodule ExampleMalformedIssueRef do
          def bar(x) do
            Blocked.by("this cannot be parsed") do
              x * x
            end
          end
        end
      end)

      assert(io =~ """
      \e[33mwarning: \e[0m`Blocked.by`: Cannot parse issue reference `this cannot be parsed`
      ------------------------
      """)
    end


    test "Passing garbage to `Blocked.by` raises an ArgumentError at compile-time" do
      assert_raise(ArgumentError, fn ->
        defmodule ExampleImproperIssueRefType do
          def bar(x) do
            Blocked.by(42) do
              x * x
            end
          end
        end
      end)
    end
  end

  describe "non-hard-coded strings passed to `Blocked.by`" do
    test "module attribute" do
      io = capture_io(:stderr, fn ->
        defmodule ExampleModuleAttribute do
          @issue_ref "elixir-blocked#1"
          def bar(x) do
            Blocked.by(@issue_ref) do
              x * x
            end
          end
        end
      end)
      assert(io == "")
    end
  end
end
