defmodule Blocked.Config do
  require Specify
  Specify.defconfig do
    field :project_repo, :string, default: nil
    field :project_owner, :string, default: nil
  end
end
