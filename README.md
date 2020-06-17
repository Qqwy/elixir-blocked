![](https://github.com/Qqwy/elixir-blocked/blob/master/media/blocked_logo_text_flat.svg)

`Blocked` is an Elixir-library that helps you to keep track of when hotfixes can be removed by showing compile-time warnings when issues (in your project repository or any other source-code GitHub repository) are closed.

[![hex.pm version](https://img.shields.io/hexpm/v/blocked.svg)](https://hex.pm/packages/blocked)
[![Build Status](https://travis-ci.org/Qqwy/elixir-blocked.svg?branch=master)](https://travis-ci.org/Qqwy/elixir-blocked)
[![Documentation](https://img.shields.io/badge/hexdocs-latest-blue.svg)](https://hexdocs.pm/blocked/index.html)
[![Inline docs](http://inch-ci.org/github/qqwy/elixir-blocked.svg)](http://inch-ci.org/github/qqwy/elixir-blocked)

---

Basic features:

- Runs at compile-time as a macro.
- Prints a compile-time warning any time an issue is closed that a piece of your code was waiting for.
- Works for your own project issues as well as for issues of any other GitHub-hosted repository.
- Allows specifying both 'hotfix' and optionally a 'desired' code block, to make it clear to future readers of your code what can be changed once the related issue is closed.
- Configurable to work on private repositories as well.
- By default performs only checking in Continuous Integration, to keep local compilation fast.

# Installation

The package can be installed
by adding `blocked` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:blocked, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/blocked](https://hexdocs.pm/blocked).

# Usage

1. Put `require Blocked` in your module to be able to use the exposed macro.
2. Write `Blocked.by(issue_reference, reason, do: ..., else: ...)` wherever you have to apply a temporary fix.


#### Example:

```elixir
defmodule Foo do
  require Blocked

  def y_plus_x_squared(y, x) do
    Blocked.by("some-repo/10", "Until a `pow` function exists, fall back to multiplication.") do
      y + (x * x)
    else
      y + pow(x, 2)
    end
  end
end
```

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

# Changelog

- 0.9.0 - Initial publicly-released version

# Roadmap & nice-to-haves

PR's are very much accepted!

- Maybe at some point support GitLab, Bitbucket or other repository-hosts as well?

# Attribution

This library is inspired and borrows heavily from the [Rust library of the same name](https://github.com/zacps/blocked).

# Is it any good?

[yes](https://news.ycombinator.com/item?id=3067434)
