#!/usr/bin/env bash

# Text colors
readonly red="\e[1;31m"
readonly green="\e[1;32m"
readonly yellow="\e[1;33m"
readonly white="\e[1;37m"
readonly normal="\e[m"

# log function
function log {
  case $1 in
    e|error|erro) # ERROR
      printf "[ ${red}ERRO${normal} ] $2"
      ;;
    i|info) # INFORMATION
      printf "[ ${white}INFO${normal} ] $2"
    ;;
    w|warn) # WARNING
      printf "[ ${yellow}WARN${normal} ] $2"
    ;;
    f|fail) # FAIL
      printf "[ ${red}FAIL${normal} ] $2"
    ;;
    o|ok) # OK
      printf "[  ${green}OK${normal}  ] $2"
    ;;
    *) # USAGE
      printf "Usage: log [i|e|w|f] <message>"
    ;;
  esac
}

# ZZ variables treatment. Checks if an environment variable is defined, and ask
# user for value if not.
# After that, save it in docker-compose .env file
# Arguments:
#  [--env-file] env file to write (default to $PREFIX/prozzie/.env)
#  Variable name
#  Default if empty text introduced ("" for error raising)
#  Question text
function zz_variable () {
  if [[ $1 == --env-file=* ]]; then
    local readonly env_file="${1#--env-file=}"
    shift
  else
    local readonly env_file="$PREFIX/prozzie/.env"
  fi

  if [[ -z "${!1}" ]]; then
    if [[ ! -z "$2" ]]; then
      local readonly default=" [$2]"
    fi
    read -rp "$3$default:" $1
  fi

  if [[ -z "${!1}" ]]; then
    if [[ ! -z "$2" ]]; then
      read -r $1 <<< "$2"
    else
      log fail "[${!1}][$2] Empty $1 not allowed"
      exit 1
    fi
  fi

  if [[ $1 != PREFIX ]]; then
    printf "%s=%s\n" "$1" "${!1}" >> "$env_file"
  fi
}

# Update zz variables array default values using a docker-compose .env file. If
# variable it's not contained in $2, copy it to .env file
# Arguments:
#  $1 source .env file
#  $2 destination .env file
#  $3 Array to update
function zz_variables_env_update_array {
  # TODO: bash >4.3, proper way is [local -n zz_vars_array=$3]. Alternative:
  eval "declare -A zz_vars_array="${3#*=}

  while IFS='=' read -r var_key var_val || [[ -n "$var_key" ]]; do
    if [ ${zz_vars_array[$var_key]+_} ]; then
      # Update zz variable
      local readonly prompt=$(cut -d '|' -f 2 <<< ${zz_vars_array[$var_key]})
      zz_vars_array[$var_key]=$(printf "%s|%s" "$var_val" "$prompt")
    else
      # Copy to output .env file
      printf "%s=%s\n" "$var_key" "$var_val" >> "$2"
    fi
  done < "$1"

  # TODO bash >4.3 hack. We don't need this with bash>4.3
  local -r ret="$(declare -p zz_vars_array)"
  printf "%s" "${ret#*=}"
}

# Ask user for a single ZZ variable
# Arguments:
#  $1 env file to save variables
#  $2 Array with variables
#  $3 Variable to ask user for
# Notes:
#  - If environment variable is defined, user will not be asked for value
function zz_variable_ask {
  local var_default
  local var_prompt
  # TODO: When bash >4.3, proper way is [local -n var_array=$2]. Alternative:
  eval "declare -A var_array="${2#*=}

  IFS='|' read var_default var_prompt <<< "${var_array[$3]}"
  zz_variable --env-file="$1" "$3" "$var_default" "$var_prompt"
}

# Ask user for ZZ module variables
# Arguments:
#  $1 env file to save variables
#  $2 Array with variables
function zz_variables_ask {
  # TODO: When bash >4.3, proper way is [local -n zz_variables=$2]. Alternative:
  eval "declare -A zz_variables="${2#*=}

  for var_key in "${!zz_variables[@]}"; do
    # TODO: When bash >4.3, proper way is [zz_variable_ask "$1" $2 "$var_key"]. Alternative:
    zz_variable_ask "$1" "$(declare -p zz_variables)" "$var_key"
  done
}

# Default prefix installation path
readonly DEFAULT_PREFIX="/usr/local"