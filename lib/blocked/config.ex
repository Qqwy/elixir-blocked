defmodule Blocked.Config do
  require Specify
  Specify.defconfig do
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
  end
end
