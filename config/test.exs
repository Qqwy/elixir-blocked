use Mix.Config

# Run Blocked in the test-environment,
# even though we're not in a CI.
config :blocked, [
  warn: true,
  github_api_token: "39f288d7c45d6f82c55a23e117ead0c2c9f35192"
]
