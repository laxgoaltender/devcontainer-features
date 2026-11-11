#!/usr/bin/env bash

set -e

rm -rf /var/lib/apt/lists/*

KOMPOSE_VERSION=${VERSION:-"latest"}

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

install_kompose()
{
	echo "Installing kompose"

	if [ "${KOMPOSE_VERSION}" = "none" ] || type kompose > /dev/null 2>&1; then
	    echo "Kompose already installed. Skipping..."
	else
		if [ "${KOMPOSE_VERSION}" = "latest" ]; then
			# Fetch the latest sealed-secrets version using GitHub API
			KOMPOSE_VERSION=$(curl -s https://api.github.com/repos/kubernetes/kompose/tags | jq -r '.[0].name' | cut -c 2-)
		fi

		if [ -z "$KOMPOSE_VERSION" ]; then
		    echo "Failed to fetch the latest KOMPOSE_VERSION"
		    exit 1
		fi

		curl -L https://github.com/kubernetes/kompose/releases/download/v${KOMPOSE_VERSION}/kompose-linux-amd64 -o kompose
		mv kompose /usr/local/bin
		chmod 0755 /usr/local/bin/kompose
	fi
}

setup_shell_completion()
{
	# flux bash completion
    kompose completion bash > /etc/bash_completion.d/kompose

    # flux zsh completion
    if [ -e "${USERHOME}/.oh-my-zsh" ]; then
        mkdir -p "${USERHOME}/.oh-my-zsh/completions"
        kompose completion zsh > "${USERHOME}/.oh-my-zsh/completions/_kompose"
        chown -R "${USERNAME}" "${USERHOME}/.oh-my-zsh"
    fi
}

apt_get_update
install_dependencies
install_kompose
setup_shell_completion

set +e

echo "Done!"
