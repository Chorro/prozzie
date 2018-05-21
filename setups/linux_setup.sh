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
declare -r PROZZIE_VERSION=0.4.0

. /etc/os-release

declare -r installer_directory=$(dirname "${BASH_SOURCE[0]}")
declare -r common_filename="${installer_directory}/../cli/include/common.bash"
declare -r config_filename="${installer_directory}/../cli/include/config.bash"
declare -r cli_filename="${installer_directory}/../cli/include/cli.bash"

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

# Directories created at installation
declare -a created_files

. "${common_filename}"
. "${config_filename}"
. "${cli_filename}"

if command_exists sudo; then
    declare -r sudo=sudo
fi

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
show_banner () {
    cat<<-EOF
	__          ___         _        _____                  _
	\ \        / (_)       (_)      |  __ \                (_)
	 \ \  /\  / / _ _________  ___  | |__) | __ ___ _________  ___
	  \ \/  \/ / | |_  /_  / |/ _ \ |  ___/ '__/ _ \_  /_  / |/ _ \\
	   \  /\  /  | |/ / / /| |  __/ | |   | | | (_) / / / /| |  __/
	    \/  \/   |_/___/___|_|\___| |_|   |_|  \___/___/___|_|\___|

	EOF
}

# Install a program
function install {
    log info "Installing $1 dependency..."
    $sudo $PKG_MANAGER install -y $1 # &> /dev/null
    printf "Done!\n"
}

# Uninstall a program
function uninstall {
    log info "Uninstalling $1 dependency..."
    $sudo $PKG_MANAGER remove -y $1 &> /dev/null
    printf "Done!\n"
}

# Update repository
function update {

  case $PKG_MANAGER in
    apt-get) # Ubuntu/Debian
      log info "Updating apt package index..."
      $sudo $PKG_MANAGER update &> /dev/null
      printf "Done!\n"
    ;;
    yum) # CentOS
      log info "Updating yum package index..."
      $sudo $PKG_MANAGER makecache fast &> /dev/null
      printf "Done!\n"
    ;;
    dnf) # Fedora
      log info "Updating dnf package index..."
      $sudo $PKG_MANAGER makecache fast &> /dev/null
      printf "Done!\n"
    ;;
    *)
      log error "Usage: update\n"
    ;;
  esac

}

# Trap function to rollback installation
# Arguments:
#  -
#
# Environment:
#  created_files - Installation created directories.
#
# Out:
#  -
#
# Exit points:
#  -
#
# Exit status:
#  -
install_rollback () {
    rm -rf "${created_files[@]}"
    print_not_modified_warning
}

# Trap function to stop prozzie and call install_rollback
# Arguments:
#  -
#
# Environment:
#  created_files - Installation created directories.
#  PREFIX - Where to search for prozzie installation to set it down
#
#
# Out:
#  -
#
# Exit points:
#  -
#
# Exit status:
#  -
stop_prozzie_install_rollback () {
    "${PREFIX}/bin/prozzie" down
    install_rollback
}


# Create prozzie directory tree
# Arguments:
#  -
#
# Environment:
#  PREFIX - Where to create the directory tree
#  created_files - Array of created directories
#
# Out:
#  mkdir errors by stderr
#
# Exit points:
#  If any directory could not be created, it will call to exit
#
# Exit status:
#  Always 0
create_directory_tree () {
    declare -r directories=("${PREFIX}/"{share/prozzie/cli,bin,etc/prozzie})
    declare mkdir_out
    mkdir_out=$(mkdir -vp "${directories[@]}")
    if [[ $? != 0 ]]; then
        exit $?
    fi

    readarray -t created_files < <(printf '%s\n' "${mkdir_out}")

    # Remove mkdir unused output: All but string between the first and last
    # quote
    created_files=( "${created_files[@]%\'}" )
    created_files=( "${created_files[@]#*\'}" )
}

# Create the prozzie CLI directory tree under $PREFIX
# Arguments:
#  -
#
# Environment:
#  installer_directory - Installer execution path
#  PREFIX - Where to create CLI directory tree
#
# Out:
#  cp errors
#
# Exit points:
#  If any file could not be created, it will call to exit
#
# Exit status:
#  Always 0
install_cli () {
    declare -r cli_base_dir="${installer_directory}/../cli"
    declare -r cli_dst_dir="${PREFIX}/share/prozzie"
    cp -r -- "${cli_base_dir}" "${cli_dst_dir}"
    if [[ ! -L "${PREFIX}/bin/prozzie" ]]; then
        created_files+=("${PREFIX}/bin/prozzie")
        ln -s "${cli_dst_dir}/cli/prozzie.bash" "${PREFIX}/bin/prozzie"
    fi
}

function app_setup () {
  # Architecture
  local -r ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')

  # List of needed depedencies for prozzie
  local -r NEEDED_DEPENDENCIES="curl net-tools"
  # List of installed dependencies
  local INSTALLED_DEPENDENCIES=""
  # Package manager for install, uninstall and update
  local PKG_MANAGER=""
  local reply  # Variable for user answers

  ID=${ID,,}

  # Clear screen
  clear

  # Show "Wizzie Prozzie" banner
  show_banner

  # Print user system information
  printf "System information: \n\n"
  printf "  OS: $PRETTY_NAME\n  Architecture: $ARCH\n\n"

  # Check architecture
  if [[ $ARCH -ne 64 ]]; then
    log error "You need 64 bits OS. Your current architecture is: $ARCH"
    exit 1
  fi

  # Special treatment of PREFIX variable
  zz_variable_ask "/dev/null" PREFIX
  unset "module_envs[PREFIX]"

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
      install $DEPENDENCY
    fi
  done

  # Check if docker is installed in current OS
  type docker &> /dev/null

  if [[ $? -eq 1 ]]; then
    log warn "Docker is not installed!\n"
    log info "Initializing docker installation!\n"

    if [[ $ID =~ ^\"?(ubuntu|debian)\"?$ ]]; then
      log info "Installing packages to allow apt to use repository over HTTPS..."
      $sudo apt-get install -y \
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
            curl -fsSL https://download.docker.com/linux/debian/gpg | $sudo apt-key add - &> /dev/null
            printf "Done!\n"

            # Set up the stable repository
            log info "Setting up Docker's stable repository..."
            $sudo add-apt-repository \
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
              $sudo apt-get install -y \
                linux-image-extra-$(uname -r) \
                linux-image-extra-virtual &> /dev/null
            fi

            # Install Docker's dependencies
            log info "Installing docker dependencies..."
            install software-properties-common &> /dev/null
            printf "Done!\n"

            # Add Docker's official GPG key
            log info "Adding Docker's official GPG key..."
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $sudo apt-key add - &> /dev/null
            printf "Done!\n"

            # Set up the stable repository
            log info "Setting up Docker's stable repository..."
            $sudo add-apt-repository \
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
            $sudo yum-config-manager \
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
            $sudo dnf config-manager \
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

    if read_yn_response "Do you want that docker to start on boot?"; then
      case $ID in
        debian|ubuntu)
          $sudo systemctl enable docker &> /dev/null
        ;;
        fedora|centos)
          $sudo systemctl start docker &> /dev/null
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
    $sudo curl -s -L "https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose &> /dev/null
    # Add permissions
    $sudo chmod +x /usr/bin/docker-compose &> /dev/null
    printf "Done!\n"
  fi

  # Get installed docker-compose version
  DOCKER_COMPOSE_VERSION=$(docker-compose --version) 2> /dev/null
  log ok "Installed: $DOCKER_COMPOSE_VERSION\n\n"

  declare -r src_env_file="${PREFIX}/etc/prozzie/.env"
  declare -r docker_compose_file="${PREFIX}/share/prozzie/docker-compose.yml"
  create_directory_tree
  trap install_rollback EXIT

  log info "Prozzie will be installed under: [${PREFIX}]\n"

  declare tmp_env
  tmp_fd tmp_env
  if [[ -f "$src_env_file" ]]; then
    # Copy not interested variables and take previous values.
    zz_variables_env_update_array "$src_env_file" "/dev/fd/$tmp_env"
  fi

  log info "Installing ${PROZZIE_VERSION} release of Prozzie...\n"
  cp -- "${installer_directory}/../docker-compose.yml" \
        "${docker_compose_file}"

  if [[ -z $INTERFACE_IP ]] && \
                      read_yn_response \
                        "Do you want discover the IP address automatically?"; \
  then
      MAIN_INTERFACE=$(route -n | awk '{printf("%s %s\n", $1, $8)}' | grep 0.0.0.0 | awk '{printf("%s", $2)}')
      INTERFACE_IP=$(ifconfig ${MAIN_INTERFACE} | grep inet | grep -v inet6 | awk '{printf("%s", $2)}' | sed -E -e 's/(inet|addr)://')
  fi

  zz_variables_ask "/dev/fd/${tmp_env}"

  cp -- "/dev/fd/$tmp_env" "$src_env_file"
  {tmp_env}<&-
  install_cli
  # Need for kafka connect modules configuration.
  "${PREFIX}/bin/prozzie" up -d kafka-connect
  trap stop_prozzie_install_rollback EXIT

  "${PREFIX}/bin/prozzie" config --wizard

  printf "Done!\n\n"

  log ok "Prozzie installation is finished!\n"
  trap '' EXIT # No need for file cleanup anymore
  log info "Starting Prozzie...\n\n"

  "${PREFIX}/bin/prozzie" start
}

# Allow inclusion on other modules with no app_setup call
if [[ "$1" != "--source" ]]; then
  app_setup
fi
