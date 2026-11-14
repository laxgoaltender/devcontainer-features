#!/usr/bin/env bash

# This test file will be executed against one of the scenarios devcontainer.json test that
# includes the 'flux2' feature with "version": "latest" option.

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "execute command" bash -c "flux -v | grep 'flux version 2.1.2'"
check "execute command" bash -c "flux9s --version | grep 'flux9s 1.5.0'"

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
