defmodule BlockedTest do
  use ExUnit.Case
  doctest Blocked

  test "greets the world" do
    assert Blocked.hello() == :world
  end
end
