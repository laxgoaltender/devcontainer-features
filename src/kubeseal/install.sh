#!/usr/bin/env bash

set -e

rm -rf /var/lib/apt/lists/*

KUBESEAL_VERSION=${VERSION:-"latest"}

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

install_kubeseal()
{
	echo "Installing kubeseal"

	if [ "${KUBESEAL_VERSION}" = "none" ] || type kubeseal > /dev/null 2>&1; then
	    echo "Kubeseal already installed. Skipping..."
	else
		if [ "${KUBESEAL_VERSION}" = "latest" ]; then
			# Fetch the latest sealed-secrets version using GitHub API
			KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami/sealed-secrets/tags | jq -r '.[0].name' | cut -c 2-)
		fi

		if [ -z "$KUBESEAL_VERSION" ]; then
		    echo "Failed to fetch the latest KUBESEAL_VERSION"
		    exit 1
		fi

		curl -OL --output-dir /tmp "https://github.com/bitnami/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
		tar -xvzf /tmp/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz --directory=/usr/local/bin/ kubeseal
		chmod 0755 /usr/local/bin/kubeseal

		rm -f /tmp/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz
	fi
}

apt_get_update
install_dependencies
install_kubeseal

set +e

echo "Done!"
