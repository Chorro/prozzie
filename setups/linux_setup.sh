#!/usr/bin/env bash

# Prozzie - Wizzie Data Platform (WDP) main entrypoint
# Copyright (C) 2018 Wizzie S.L.

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


declare -r GITHUB_ACCESS_TOKEN=4ea54f05cd7111c2e886f2c26f59b99109245053
declare -r PROZZIE_VERSION=0.4.0-pre2

. /etc/os-release

declare -r installer_directory=$(dirname "${BASH_SOURCE[0]}")
declare -r common_filename="${installer_directory}/common.sh"
if [[ ! -f "${common_filename}" ]]; then
    # We are probably being called from download. Need to download prozzie
    declare -r tmp_dir=$(mktemp -d)
    trap "rm -rf $(printf '%q' "${tmp_dir}")" EXIT
    declare -r tarball_endpoint="wizzie-io/prozzie/archive/${PROZZIE_VERSION}.tar.gz"
    (cd "$tmp_dir";
        curl -L \
        "https://${GITHUB_ACCESS_TOKEN}@github.com/${tarball_endpoint}" |
        tar xzp;
        "./prozzie-${PROZZIE_VERSION}/setups/linux_setup.sh"
        )
    exit $?
fi

. "${common_filename}"

# [env_variable]="default|prompt"
declare -A module_envs=(
  [PREFIX]="${DEFAULT_PREFIX}|Where do you want install prozzie?"
  [INTERFACE_IP]='|Introduce the IP address'
  [CLIENT_API_KEY]='|Introduce your client API key'
  [ZZ_HTTP_ENDPOINT]='|Introduce the data HTTPS endpoint URL (use http://.. for plain HTTP)')

function ZZ_HTTP_ENDPOINT_sanitize() {
  declare out="$1"
  if [[ ! "$out" =~ ^http[s]?://* ]]; then
    declare out="https://${out}"
  fi
  if [[ ! "$out" =~ /v1/data[/]?$ ]]; then
    declare out="${out}/v1/data"
  fi
  printf "%s" "$out"
}

# Wizzie Prozzie banner! :D
function show_banner {
  printf " __          ___         _        _____                  _      \n \ \        / (_)       (_)      |  __ \                (_)     \n  \ \  /\  / / _ _________  ___  | |__) | __ ___ _________  ___ \n   \ \/  \/ / | |_  /_  / |/ _ \ |  ___/ '__/ _ \_  /_  / |/ _ \ \n    \  /\  /  | |/ / / /| |  __/ | |   | | | (_) / / / /| |  __/\n     \/  \/   |_/___/___|_|\___| |_|   |_|  \___/___/___|_|\___|\n\n"
}

# Install a program
function install {
    log info "Installing $1 dependency..."
    sudo $PKG_MANAGER install -y $1 # &> /dev/null
    printf "Done!\n"
}

# Uninstall a program
function uninstall {
    log info "Uninstalling $1 dependency..."
    sudo $PKG_MANAGER remove -y $1 &> /dev/null
    printf "Done!\n"
}

# Update repository
function update {

  case $PKG_MANAGER in
    apt-get) # Ubuntu/Debian
      log info "Updating apt package index..."
      sudo $PKG_MANAGER update &> /dev/null
      printf "Done!\n"
    ;;
    yum) # CentOS
      log info "Updating yum package index..."
      sudo $PKG_MANAGER makecache fast &> /dev/null
      printf "Done!\n"
    ;;
    dnf) # Fedora
      log info "Updating dnf package index..."
      sudo $PKG_MANAGER makecache fast &> /dev/null
      printf "Done!\n"
    ;;
    *)
      log error "Usage: update\n"
    ;;
  esac

}

# Custom `select` implementation
# Pass the choices as individual arguments.
# Output is the chosen item, or "", if the user just pressed ENTER.
zz_select () {
    declare -r invalid_selection_message="Invalid selection. Please try again."
    local item i=0 numItems=$#

    # Print numbered menu items, based on the arguments passed.
    for item; do         # Short for: for item in "$@"; do
        printf '%s\n' "$((++i))) $item"
    done >&2 # Print to stderr, as `select` does.

    # Prompt the user for the index of the desired item.
    while :; do
        printf %s "${PS3-#? }" >&2
        read -r index

        # Make sure that the input is either empty, idx or text.
        [[ -z $index ]] && return  # empty input
        if [[ $index =~ ^-?[0-9]+$ ]]; then
            # Answer is a number
            (( index >= 1 && index <= numItems )) 2>/dev/null || \
                { echo "${invalid_selection_message}" >&2; continue; }
            printf %s "${@: index:1}"
            return
        fi

        # Input is string
        for arg in "$@"; do
            if [[ $arg == $index ]]; then
                printf "%s" "$arg"
                return
            fi
        done

        # Non-blank unknown response
        log error "$invalid_selection_message" >&2;
    done
}

# Search for modules in a specific directory and offers them to the user to
# setup them
# Arguments:
#  1 - Directory to search modules from
#  2 - Current temp env file
#  3 - (Optional) list of modules to configure
setup_modules () {
    declare -r PS3='Do you want to configure modules? (Enter for quit)'
    declare -a modules config_modules
    declare reply
    read -r -a config_modules <<< "$3"

    pushd -- "$1" >/dev/null 2>&1
    for module in ./*_setup.sh; do
        if [[ $module == './linux_setup.sh' ]]; then
            continue
        fi

        # Parameter expansion deletes './' and '_setup.sh'
        modules[${#modules[@]}]="${module:2:-9}"
    done

    while :; do
        if [[ -z ${3+x} ]]; then
            reply=$(zz_select "${modules[@]}")
        elif [[ ${#config_modules[@]} > 0 ]]; then
            reply=${config_modules[-1]}
        else
            reply=''
        fi

        if [[ -z ${reply} ]]; then
            break
        fi

        log info "Configuring ${reply} module\n"

        set +m  # Send SIGINT only to child
        (ENV_FILE="$2" "./${reply}_setup.sh" --no-reload-prozzie)
        set -m
    done
    popd >/dev/null 2>&1
}

function app_setup () {
  # Architecture
  local -r ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

  # List of needed depedencies for prozzie
  local -r NEEDED_DEPENDENCIES="curl jq net-tools"
  # List of installed dependencies
  local INSTALLED_DEPENDENCIES=""
  # Package manager for install, uninstall and update
  local PKG_MANAGER=""
  local reply  # Variable for user answers

  ID=${ID,,}

  # Clear screen
  clear

  if [[ $EUID -ne 0 ]]; then
    log warn "You must be a root user for running this script. Please use sudo\n"
    exit 1
  fi

  # Show "Wizzie Prozzie" banner
  show_banner

  # Print user system information
  printf "System information: \n\n"
  printf "  OS: $PRETTY_NAME\n  Architecture: $ARCH\n\n"

  # Check architecture
  if [[ $ARCH -ne 64 ]]; then
    log error "You need 64 bits OS. Your current architecture is: $ARCH"
  fi

  # Special treatment of PREFIX variable
  # TODO: When bash >4.3, proper way is [zz_variable_ask "/dev/null" module_envs PREFIX]. Alternative:
  zz_variable_ask "/dev/null" "$(declare -p module_envs)" PREFIX
  unset "module_envs[PREFIX]"

  if [[ ! -d "$PREFIX" ]]; then
    log error "The directory [$PREFIX] doesn't exist. Re-run Prozzie installer and enter a valid path.\n"
    exit 1
  fi

  local -r src_env_file="$PREFIX/prozzie/.env"

  log info "Prozzie will be installed in: [$PREFIX]\n"

  # Set PKG_MANAGER first time
  case $ID in
    debian|ubuntu)
      PKG_MANAGER="apt-get"
    ;;
    centos)
      PKG_MANAGER="yum"
    ;;
    fedora)
      PKG_MANAGER="dnf"
    ;;
    *)
      log error "This linux distribution is not supported! You need Ubuntu, Debian, Fedora or CentOS linux distribution\n"
      exit 1
    ;;
  esac

  # Update repository
  update

  # Install needed dependencies
  for DEPENDENCY in $NEEDED_DEPENDENCIES; do

    # Check if dependency is installed in current OS
    type $DEPENDENCY &> /dev/null

    if [[ $? -eq 1 ]]; then

      # CentOS systems only
      if [[ $DEPENDENCY == jq && $ID == centos ]]; then
        install epel-release
      fi

      install $DEPENDENCY
      INSTALLED_DEPENDENCIES="$INSTALLED_DEPENDENCIES $DEPENDENCY"
    fi
  done

  # Check if docker is installed in current OS
  type docker &> /dev/null

  if [[ $? -eq 1 ]]; then
    log warn "Docker is not installed!\n"
    log info "Initializing docker installation!\n"

    if [[ $ID =~ ^\"?(ubuntu|debian)\"?$ ]]; then
      log info "Installing packages to allow apt to use repository over HTTPS..."
      sudo apt-get install -y \
        apt-transport-https \
        ca-certificates &> /dev/null
      printf "Done!\n"
    fi

    # Install docker dependencies
    case $ID in
      debian)
          if [[ $VERSION_ID =~ ^\"?[87].*\"?$ ]]; then

            # Install packages to allow apt to use a repository over HTTPS:
            if [[ ${VERSION,,} =~ ^\"?.*whezzy.*\"?$ ]]; then
               install python-software-properties &> /dev/null
            elif [[ ${VERSION,,} =~ ^\"?.*stretch.*\"?$ || $VERSION =~ ^\"?.*jessie.*\"?$ ]]; then
               install software-properties-common &> /dev/null
            fi

            # Add Docker’s official GPG key:
            log info "Adding Docker's official GPG key..."
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - &> /dev/null
            printf "Done!\n"

            # Set up the stable repository
            log info "Setting up Docker's stable repository..."
            sudo add-apt-repository \
              "deb [arch=amd64] https://download.docker.com/linux/debian \
              $(lsb_release -cs) \
              stable" &> /dev/null
            printf "Done!\n"

          else
            log error "You need Debian 8.0 or 7.7. Your current Debian version is: $VERSION_ID\n"
            exit 1
          fi
      ;;
      ubuntu)
          if [[ $VERSION_ID =~ ^\"?1[46].*\"?$ ]]; then

            # Version 14.04 (Trusty)
            if [[ ${VERSION_ID,,} =~ ^\"?.*trusty.*\"?$  ]]; then
              sudo apt-get install -y \
                linux-image-extra-$(uname -r) \
                linux-image-extra-virtual &> /dev/null
            fi

            # Install Docker's dependencies
            log info "Installing docker dependencies..."
            install software-properties-common &> /dev/null
            printf "Done!\n"

            # Add Docker's official GPG key
            log info "Adding Docker's official GPG key..."
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &> /dev/null
            printf "Done!\n"

            # Set up the stable repository
            log info "Setting up Docker's stable repository..."
            sudo add-apt-repository \
              "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
              $(lsb_release -cs) \
              stable" &> /dev/null
            printf "Done!\n"

          else
            log error "You need Ubuntu 16.10, 16.04 or 14.04. Your current Ubuntu version is: $VERSION_ID\n"
            exit 1
          fi
      ;;
      centos)
          if [[ $VERSION_ID =~ ^\"?7.*\"?$ ]]; then

            log info "Installing necessary packages for set up repository..."
            install yum-utils &> /dev/null
            printf "Done!\n"

            # Set up the stable repository
            log info "Setting up Docker's stable repository..."
            sudo yum-config-manager \
                 --add-repo \
                 https://download.docker.com/linux/centos/docker-ce.repo &> /dev/null
            printf "Done!\n"

          else
            log error "You need CentOS 7. Your current CentOS version is: $VERSION_ID\n"
            exit 1
          fi
      ;;
      fedora)
          if [[ $VERSION_ID =~ ^\"?2[45]\"?$ ]]; then

            # Update repository
            update

            log info "Installing necessary packages for set up repository..."
            install dnf-plugins-core &> /dev/null
            printf "Done!\n"

            # Set up the stable repository
            log info "Setting up Docker's stable repository..."
            sudo dnf config-manager \
                 --add-repo \
                 https://download.docker.com/linux/fedora/docker-ce.repo &> /dev/null
            printf "Done!\n"

          else
            log error "You need Fedora 24 or 25. Your current Fedora version is: $VERSION_ID\n"
            exit 1
          fi
      ;;
      *)
            log error "This linux distribution is not supported! You need Ubuntu, Debian, Fedora or CentOS linux distribution\n"
            exit 1
      ;;
    esac

    # Update repository
    update

    log info "Installing the latest version of Docker Community Edition..."
    $PKG_MANAGER install -y docker-ce &> /dev/null;
    printf "Done!\n\n"

    # Configure Docker to start boot
    reply=$(read_yn_response "Do you want that docker to start on boot?")
    printf "\n\n"

    if [[ $reply == y || -z $reply ]]; then
      case $ID in
        debian|ubuntu)
          sudo systemctl enable docker &> /dev/null
        ;;
        fedora|centos)
          sudo systemctl start docker &> /dev/null
        ;;
      esac
      log ok "Configured docker to start on boot!\n"
    fi # Check if user response {Y}es

  fi # Check if docker is installed

  # Installed docker version
  DOCKER_VERSION=$(docker -v) 2> /dev/null
  log ok "Installed: $DOCKER_VERSION\n"

  # Check if docker-compose is installed in current OS
  type docker-compose &> /dev/null

  if [[ $? -eq 1 ]]; then
    log warn "Docker-Compose is not installed!\n"
    log info "Initializing Docker-Compose installation\n"
    # Download latest release (Not for production)
    log info "Downloading latest release of Docker Compose..."
    sudo curl -s -L "https://github.com/docker/compose/releases/download/1.11.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose &> /dev/null
    # Add permissions
    sudo chmod +x /usr/bin/docker-compose &> /dev/null
    printf "Done!\n"
  fi

  # Get installed docker-compose version
  DOCKER_COMPOSE_VERSION=$(docker-compose --version) 2> /dev/null
  log ok "Installed: $DOCKER_COMPOSE_VERSION\n\n"

  declare tmp_env
  tmp_fd tmp_env
  if [[ -f "$src_env_file" ]]; then
    trap print_not_modified_warning EXIT

    # Restore old env
    eval 'declare -A module_envs='$(zz_variables_env_update_array \
                                                    "$src_env_file" \
                                                    "/dev/fd/$tmp_env" \
                                                    "$(declare -p module_envs)")
  fi

  log info "Installing ${PROZZIE_VERSION} release of Prozzie...\n"
  cp -- "${installer_directory}/../docker-compose.yml" "$PREFIX/prozzie/"

  if [[ -z $INTERFACE_IP ]]; then
    reply=$(read_yn_response "Do you want discover the IP address automatically?")
    printf "\n"

    if [[ $reply == y || -z $reply ]]; then
      MAIN_INTERFACE=$(route -n | awk '{printf("%s %s\n", $1, $8)}' | grep 0.0.0.0 | awk '{printf("%s", $2)}')
      INTERFACE_IP=$(ifconfig ${MAIN_INTERFACE} | grep inet | grep -v inet6 | awk '{printf("%s", $2)}' | sed -E -e 's/(inet|addr)://')
    fi
  fi

  # TODO: When bash >4.3, proper way is [zz_variables_ask "$PREFIX/prozzie/.env" module_envs]. Alternative:
  zz_variables_ask "/dev/fd/${tmp_env}" "$(declare -p module_envs)"
  setup_modules \
    "${installer_directory}" "/dev/fd/${tmp_env}" ${CONFIG_APPS+"$CONFIG_APPS"}
  cp "/dev/fd/$tmp_env" "$src_env_file"
  {tmp_env}<&-

  trap '' EXIT # No need for file cleanup anymore

  # Check installed dependencies
  if ! [[ -z "$INSTALLED_DEPENDENCIES" || "x$REMOVE_DEPS" == "x0" ]]; then
    log info "This script has installed next dependencies: $INSTALLED_DEPENDENCIES\n\n"

    reply=$(read_yn_response "They are no longer needed. Would you like to uninstall?")
    printf "\n\n"

    if [[ $reply == y ]]; then
      # Uninstall dependencies
      for DEPENDENCY in $INSTALLED_DEPENDENCIES; do
        uninstall $DEPENDENCY
      done
      log info "All Prozzie dependecies have been uninstalled!\n"
    fi

  fi

  log info "Adding start and stop scripts..."

  # Create prozzie/bin directory
  mkdir -p "$PREFIX/prozzie/bin"

  echo -e "#!/bin/bash\n\n(cd $PREFIX/prozzie ; docker-compose start)" > "$PREFIX/prozzie/bin/start-prozzie.sh"
  sudo chmod +x "$PREFIX/prozzie/bin/start-prozzie.sh"

  echo -e "#!/bin/bash\n\n(cd $PREFIX/prozzie; docker-compose stop)" > "$PREFIX/prozzie/bin/stop-prozzie.sh"
  sudo chmod +x "$PREFIX/prozzie/bin/stop-prozzie.sh"

  echo -e "#!/bin/bash\n\ndocker run -i -e KAFKA_CONNECT_REST=http://${INTERFACE_IP}:8083 gcr.io/wizzie-registry/kafka-connect-cli:1.0.3 sh -c \"kcli \$*\"" > "$PREFIX/prozzie/bin/kcli.sh"
  sudo chmod +x "$PREFIX/prozzie/bin/kcli.sh"

  printf "Done!\n\n"

  if [[ ! -f /usr/bin/prozzie-start ]]; then
    sudo ln -s "$PREFIX/prozzie/bin/start-prozzie.sh" /usr/bin/prozzie-start
  fi

  if [[ ! -f /usr/bin/prozzie-stop ]]; then
    sudo ln -s "$PREFIX/prozzie/bin/stop-prozzie.sh" /usr/bin/prozzie-stop
  fi

  if [[ ! -f /usr/bin/kcli ]]; then
    sudo ln -s "$PREFIX/prozzie/bin/kcli.sh" /usr/bin/kcli
  fi

  log ok "Prozzie installation is finished!\n"
  log info "Starting Prozzie...\n\n"

  (cd "$PREFIX/prozzie"; \
  docker-compose up -d)
}

# Allow inclusion on other modules with no app_setup call
if [[ "$1" != "--source" ]]; then
  app_setup
fi
