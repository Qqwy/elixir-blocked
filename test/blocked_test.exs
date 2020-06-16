defmodule BlockedTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  doctest Blocked

  describe "Macro usage" do
    test "Integration test - happy path (requires an internet connection)" do
      io = capture_io(:stderr, fn ->
        defmodule ExampleHappy do
          def bar(x) do
            Blocked.by("elixir-blocked#1") do
              x * x
            end
          end
        end
      end)

      assert(io == "")
    end

    test "Integration test - sad path (requires an internet connection)" do
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
  end
end
