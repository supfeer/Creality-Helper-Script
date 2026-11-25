#!/bin/sh

set -e

system_menu_ui() {
  memfree=`cat /proc/meminfo | grep MemFree | awk {'print $2'}`
  memtotal=`cat /proc/meminfo | grep MemTotal | awk {'print $2'}`
  pourcent=$((($memfree * 100)/$memtotal))
  diskused=`df -h | grep /dev/mmcblk0p10 | awk {'print $3 " / " $2 " (" $4 " available)" '}`
  process=`ps ax | wc -l | tr -d " "`
  uptime=`cat /proc/uptime | cut -f1 -d.`
  formatted_uptime=$(format_uptime $uptime)
  load=`awk -v cpus=2 '{printf "%.2f%% (1 min) | %.2f%% (5 min) | %.2f%% (15 min)\n", $1*100/cpus, $2*100/cpus, $3*100/cpus}' /proc/loadavg`
  device_sn=$(cat /usr/data/creality/userdata/config/system_config.json | grep -o '"device_sn":"[^"]*' | awk -F '"' '{print $4}')
  mac_address=$(cat /usr/data/creality/userdata/config/system_config.json | grep -o '"device_mac":"[^"]*' | awk -F '"' '{print $4}' | sed 's/../&:/g; s/:$//')
  top_line
  title "$(t 'section.system.title')" "${yellow}"
  inner_line
  hr
  hr
  inner_line
  hr
  bottom_menu_option 'b' "$(t 'menu.back')" "${yellow}"
  bottom_menu_option 'q' "$(t 'menu.exit')" "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

system_menu() {
  clear
  system_menu_ui
  local system_menu_opt
  while true; do
    read -p " ${white}$(t 'prompt.choice') ${yellow}" system_menu_opt
    case "${system_menu_opt}" in
      B|b)
        clear; main_menu; break;;
      Q|q)
         clear; exit 0;;
      *)
         error_msg "$(t 'menu.invalid_choice')";;
    esac
  done
  system_menu
}
