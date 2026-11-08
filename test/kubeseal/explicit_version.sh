#!/usr/bin/env bash

# This test file will be executed against one of the scenarios devcontainer.json test that
# includes the 'flux2' feature with "version": "latest" option.

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

echo "Kubeseal version:"
kubeseal --version
# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "execute command" bash -c "kubeseal --version | grep 'kubeseal version 0.39.1'"

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
