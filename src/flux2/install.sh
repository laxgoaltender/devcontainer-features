#!/usr/bin/env bash

set -euo pipefail

rm -rf /var/lib/apt/lists/*

FLUX_VERSION=${VERSION:-"latest"}
FLUX9S_VERSION=${FLUX9S_VERSION:-"latest"}

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

install_flux()
{
	echo "Activating feature 'flux2'"

	if [ "${FLUX_VERSION}" = "none" ] || type flux > /dev/null 2>&1; then
	    echo "FLux already installed. Skipping..."
	else

	  echo "Installing flux...'"

	  if [ "${FLUX_VERSION}" = "latest" ] ; then
	    curl -s https://fluxcd.io/install.sh | bash
	  else
	    curl -s https://fluxcd.io/install.sh | FLUX_VERSION=$FLUX_VERSION bash
	  fi
	
	fi
}

install_flux9s()
{
	echo "Installing flux9s"

	if [ "${FLUX9S_VERSION}" = "none" ] || type flux9s > /dev/null 2>&1; then
	    echo "flux9s already installed or not selected. Skipping..."
	else
		if [ "${FLUX9S_VERSION}" = "latest" ]; then
			# Fetch the latest sealed-secrets version using GitHub API
			FLUX9S_VERSION=$(curl -s https://api.github.com/repos/dgunzy/flux9s/tags | jq -r '.[0].name' | cut -c 2-)
		fi

		if [ -z "$FLUX9S_VERSION" ]; then
		    echo "Failed to fetch the latest flux9s version"
		    exit 1
		fi

		curl -OL --output-dir /tmp "https://github.com/dgunzy/flux9s/releases/download/v${FLUX9S_VERSION}/flux9s-linux-X86_64-gnu.tar.gz"
		tar -xvzf /tmp/flux9s-linux-X86_64-gnu.tar.gz --directory=/usr/local/bin/ flux9s
		chmod 0755 /usr/local/bin/flux9s

		rm -f /tmp/flux9s-linux-X86_64-gnu.tar.gz
	fi
}

setup_shell_completion()
{
	binary=$1
	completion_arg=$2
	# bash completion
    $binary $completion_arg bash > "/etc/bash_completion.d/${binary}"

    # flux zsh completion
    if [ -e "${USERHOME}/.oh-my-zsh" ]; then
        mkdir -p "${USERHOME}/.oh-my-zsh/completions"
        $binary $completion_arg zsh > "${USERHOME}/.oh-my-zsh/completions/_${binary}"
        chown -R "${USERNAME}" "${USERHOME}/.oh-my-zsh"
    fi
}

apt_get_update
install_dependencies
install_flux
setup_shell_completion flux completion

if [ "${FLUX9S_VERSION}" != "none" ]; then
	install_flux9s
	setup_shell_completion flux9s completions
fi

set +e

echo "Done!"
