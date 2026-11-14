#!/usr/bin/env bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'flux2' Feature with no options.

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "execute command" bash -c "flux -v | grep 'flux version'"
check "execute command" bash -c "flux9s --version | grep 'flux9s'"

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
