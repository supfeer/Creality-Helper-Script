#!/bin/sh

set -e

if [ -f "${HELPER_SCRIPT_FOLDER}/scripts/menu/strings.sh" ]; then
  . "${HELPER_SCRIPT_FOLDER}/scripts/menu/strings.sh"
fi

init_cli_lang() {
  if [ -n "${CLI_LANG}" ]; then
    return
  fi
  local lang=""
  if [ -n "${HS_CONFIG_FOLDER}" ] && [ -f "${HS_CONFIG_FOLDER}/cli_lang" ]; then
    lang="$(cat "${HS_CONFIG_FOLDER}/cli_lang" 2>/dev/null)"
  fi
  if [ -z "$lang" ]; then
    lang="${CLI_DEFAULT_LANG:-en}"
  fi
  CLI_LANG="$lang"
}

t() {
  init_cli_lang
  if command -v get_string >/dev/null 2>&1; then
    get_string "$1"
  else
    echo "$1"
  fi
}

format() {
  local template="$1"
  shift
  printf "$template" "$@"
}

set_cli_language() {
  local lang="$1"
  if [ -z "${HS_CONFIG_FOLDER}" ]; then
    CLI_LANG="$lang"
    return
  fi
  mkdir -p "${HS_CONFIG_FOLDER}" >/dev/null 2>&1
  echo "$lang" > "${HS_CONFIG_FOLDER}/cli_lang"
  CLI_LANG="$lang"
  ok_msg "$(t 'language.saved')"
}

function top_line() {
  echo -e "${white}"
  echo -e " ┌────────────────────────────────────────────────────────────────┐"
}

function hr() {
  echo -e " │                                                                │"
}

function inner_line() {
  echo -e " ├────────────────────────────────────────────────────────────────┤"
}

function bottom_line() {
  echo -e " └────────────────────────────────────────────────────────────────┘"
  echo -e "${white}"
}

function blank_line() {
  echo -e " "
}

function title() {
  local text=$1
  local color=$2
  local max_length=64
  local text_length=${#text}
  local padding_left=$(((max_length - text_length) / 2))
  local padding_right=$((max_length - text_length - padding_left))
  printf " │%*s${color}%s${white}%*s│\n" $padding_left '' "$text" $padding_right ''
}

function subtitle() {
  local menu_text1=$1
  local max_length=63
  local padding=$((max_length - ${#menu_text1}))
  printf " │ ${blue}${menu_text1}%-${padding}s${white}│\n" ''
}

function main_menu_option() {
  local menu_number=$1
  local menu_text1=$2
  local menu_text2=$3
  local max_length=58
  local total_text_length=$(( ${#menu_text1} + ${#menu_text2} ))
  local padding=$((max_length - total_text_length))
  printf " │  ${yellow}${menu_number}${white}) ${green}${menu_text1} ${white}${menu_text2}%-${padding}s${white}│\n" ''
}

function menu_option() {
  local menu_number=$1
  local menu_text1=$2
  local menu_text2=$3
  local max_length=62
  local total_text_length=$(( ${#menu_text1} + ${#menu_text2} + ${#menu_number} + 4 ))
  local padding=$((max_length - total_text_length))
  printf " │   ${yellow}${menu_number}${white}) ${white}${menu_text1} ${green}${menu_text2}%-${padding}s${white}│\n" ''
}

function bottom_menu_option() {
  local menu_number=$1
  local menu_text=$2
  local color=$3
  local max_length=59
  local padding=$((max_length - ${#menu_text}))
  printf " │  $color${menu_number}${white}) ${white}${menu_text}%-${padding}s${white}│\n" ''
}

function info_line() {
  local status=$1
  local text=$2
  local color=$3
  local max_length=68
  local total_text_length=$(( ${#status} + ${#text} ))
  local padding=$((max_length - total_text_length))
  printf " │   $color${status} ${white}${text}%-${padding}s${white}│\n" ''
}

function system_line() {
  local title="$1"
  local value="$2"
  local max_length=63
  local title_length=${#title}
  local separator=": "
  local value_length=${#value}
  local value_padding=$((max_length - title_length - ${#separator} - value_length))
  printf " │ ${green}%s${white}%s${white}\e[97m%s%-*s%s${white}│\n" "$title" "$separator" "$value" $value_padding ''
}

function install_msg() {
  if [ "${HELPER_NONINTERACTIVE:-0}" = "1" ]; then
    eval "$2=y"
    return
  fi
  local prompt
  prompt="$(format "$(t 'confirm.install')" "${green}${1}${white}")"
  if ! read -p "${white} ${prompt} (${yellow}y${white}/${yellow}n${white}): ${yellow}" $2; then
    eval "$2=n"
  fi
}

function remove_msg() {
  if [ "${HELPER_NONINTERACTIVE:-0}" = "1" ]; then
    eval "$2=y"
    return
  fi
  local prompt
  prompt="$(format "$(t 'confirm.remove')" "${green}${1}${white}")"
  if ! read -p "${white} ${prompt} (${yellow}y${white}/${yellow}n${white}): ${yellow}" $2; then
    eval "$2=n"
  fi
}

function restore_msg() {
  if [ "${HELPER_NONINTERACTIVE:-0}" = "1" ]; then
    eval "$2=y"
    return
  fi
  local prompt
  prompt="$(format "$(t 'confirm.restore')" "${green}${1}${white}")"
  if ! read -p "${white} ${prompt} (${yellow}y${white}/${yellow}n${white}): ${yellow}" $2; then
    eval "$2=n"
  fi
}

function backup_msg() {
  if [ "${HELPER_NONINTERACTIVE:-0}" = "1" ]; then
    eval "$2=y"
    return
  fi
  local prompt
  prompt="$(format "$(t 'confirm.backup')" "${green}${1}${white}")"
  if ! read -p "${white} ${prompt} (${yellow}y${white}/${yellow}n${white}): ${yellow}" $2; then
    eval "$2=n"
  fi
}

function restart_msg() {
  if [ "${HELPER_NONINTERACTIVE:-0}" = "1" ]; then
    eval "$2=y"
    return
  fi
  local prompt
  prompt="$(format "$(t 'confirm.restart')" "${green}${1}${white}")"
  if ! read -p "${white} ${prompt} (${yellow}y${white}/${yellow}n${white}): ${yellow}" $2; then
    eval "$2=n"
  fi
}

function ok_msg() {
  echo
  echo -e "${white}${green} ✓ ${1}${white}"
  echo
}

function error_msg() {
  echo
  echo -e "${white}${darkred} ✗ ${1}${white}"
  echo
}

function check_file() {
  local file_path="$1"
  if [ -f "$file_path" ]; then
    echo -e "${green}✓"
  else
    echo -e "${red}✗"
  fi
}

function check_dir() {
  local folder_path="$1"
  if [ -d "$folder_path" ]; then
    echo -e "${green}✓"
  else
    echo -e "${red}✗"
  fi
}

function check_simplyprint() {
  if [ ! -f "$MOONRAKER_CFG" ]; then
    echo -e "${red}✗"
  elif grep -q "\[simplyprint\]" "$MOONRAKER_CFG"; then
    echo -e "${green}✓"
  else
    echo -e "${red}✗"
  fi
}

function run() {
  clear
  # $1 - Action performed
  $1
  # $2 - Menu launched after action is completed
  $2
}

function check_ipaddress() {
  eth0_ip=$(ip -4 addr show eth0 2>/dev/null | grep -o -E '(inet\s)([0-9]+\.){3}[0-9]+' | cut -d ' ' -f 2 | head -n 1 || true)
  wlan0_ip=$(ip -4 addr show wlan0 2>/dev/null | grep -o -E '(inet\s)([0-9]+\.){3}[0-9]+' | cut -d ' ' -f 2 | head -n 1 || true)
  if [ -n "$eth0_ip" ]; then
    echo -e "$eth0_ip"
  elif [ -n "$wlan0_ip" ]; then
    echo -e "$wlan0_ip"
  else
    echo -e "xxx.xxx.xxx.xxx"
  fi
}

function start_moonraker() {
  set +e
  if [ -x /etc/init.d/S56moonraker_service ]; then
    /etc/init.d/S56moonraker_service start
  elif [ -x /etc/init.d/moonraker ]; then
    /etc/init.d/moonraker start
  fi
  sleep 1
  set -e
}

function stop_moonraker() {
  set +e
  if [ -x /etc/init.d/S56moonraker_service ]; then
    /etc/init.d/S56moonraker_service stop
  elif [ -x /etc/init.d/moonraker ]; then
    /etc/init.d/moonraker stop
  fi
  sleep 1
  set -e
}

function start_nginx() {
  set +e
  if [ -x /etc/init.d/S50nginx ]; then
    /etc/init.d/S50nginx start
  elif [ -x /etc/init.d/nginx ]; then
    /etc/init.d/nginx start
  fi
  sleep 1
  set -e
}

function stop_nginx() {
  set +e
  if [ -x /etc/init.d/S50nginx ]; then
    /etc/init.d/S50nginx stop
  elif [ -x /etc/init.d/nginx ]; then
    /etc/init.d/nginx stop
  fi
  sleep 1
  set -e
}

function restart_nginx() {
  set +e
  if [ -x /etc/init.d/S50nginx ]; then
    /etc/init.d/S50nginx restart
  elif [ -x /etc/init.d/nginx ]; then
    /etc/init.d/nginx restart
  fi
  sleep 1
  set -e
}

function start_klipper() {
  set +e
  if [ -x /etc/init.d/S55klipper_service ]; then
    /etc/init.d/S55klipper_service start
  else
    /etc/init.d/klipper start
  fi
  set -e
}

function stop_klipper() {
  set +e
  if [ -x /etc/init.d/S55klipper_service ]; then
    /etc/init.d/S55klipper_service stop
  else
    /etc/init.d/klipper stop
  fi
  set -e
}

function restart_klipper() {
  set +e
  if [ -x /etc/init.d/S55klipper_service ]; then
    /etc/init.d/S55klipper_service restart
  else
    /etc/init.d/klipper restart
  fi
  set -e
}

function disabled_feature() {
  error_msg "Due to some compatibility issues, this feature is temporarily disabled!"
}
