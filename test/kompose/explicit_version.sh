#!/usr/bin/env bash

# This test file will be executed against one of the scenarios devcontainer.json test that
# includes the 'kompose' feature with "version": "latest" option.

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

echo "Kompose version:"
kompose version
# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "execute command" bash -c "kompose version | grep '1.36.0'"

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
