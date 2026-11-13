#!/usr/bin/env bash

set -e

rm -rf /var/lib/apt/lists/*

GITOPS_ZOMBIES_VERSION=${VERSION:-"latest"}

DEPENDENCIES=('bash-completion' 'ca-certificates' 'curl' 'jq')

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

USERHOME="/home/$USERNAME"
if [ "$USERNAME" = "root" ]; then
    USERHOME="/root"
fi

export DEBIAN_FRONTEND=noninteractive

apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

install_dependencies()
{
	apt-get update
	apt-get install -y --no-install-recommends "${DEPENDENCIES[@]}"
	apt-get clean all
	rm -rf /var/lib/apt/lists/*
}

install_gitops-zombies()
{
	echo "Installing gitops-zombies"

	if [ "${GITOPS_ZOMBIES_VERSION}" = "none" ] || type gitops-zombies > /dev/null 2>&1; then
	    echo "gitops-zombies already installed. Skipping..."
	else
		if [ "${GITOPS_ZOMBIES_VERSION}" = "latest" ]; then
			# Fetch the latest sealed-secrets version using GitHub API
			GITOPS_ZOMBIES_VERSION=$(curl -s https://api.github.com/repos/raffis/gitops-zombies/tags | jq -r '.[0].name' | cut -c 2-)
		fi

		if [ -z "$GITOPS_ZOMBIES_VERSION" ]; then
		    echo "Failed to fetch the latest GITOPS_ZOMBIES_VERSION"
		    exit 1
		fi

		curl -OL --output-dir /tmp "https://github.com/raffis/gitops-zombies/releases/download/v${GITOPS_ZOMBIES_VERSION}/gitops-zombies_${GITOPS_ZOMBIES_VERSION}_linux_amd64.tar.gz"
		tar -xvzf /tmp/gitops-zombies_${GITOPS_ZOMBIES_VERSION}_linux_amd64.tar.gz --directory=/usr/local/bin/ gitops-zombies
		chmod 0755 /usr/local/bin/gitops-zombies

		rm -f /tmp/gitops-zombies_${GITOPS_ZOMBIES_VERSION}_linux_amd64.tar.gz
	fi
}

apt_get_update
install_dependencies
install_gitops-zombies

set +e

echo "Done!"
