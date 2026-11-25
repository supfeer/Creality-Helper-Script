#!/bin/sh

set -e

if [ ! -f /etc/init.d/S58factoryreset ]; then
  cp /usr/data/helper-script/files/services/S58factoryreset /etc/init.d/S58factoryreset
  chmod 755 /etc/init.d/S58factoryreset
fi

get_model=$( /usr/bin/get_sn_mac.sh model 2>&1 )
if echo "$get_model" | grep -iq "K1"; then
  model="K1"
elif echo "$get_model" | grep -iq "K2"; then
  model="K2PLUS"
elif echo "$get_model" | grep -iq "F008"; then
  model="K2PLUS"
elif echo "$get_model" | grep -iq "F001"; then
  model="3V3"
elif echo "$get_model" | grep -iq "F002"; then
  model="3V3"
elif echo "$get_model" | grep -iq "F005"; then
  model="3KE"
elif echo "$get_model" | grep -iq "F003"; then
  model="10SE"
elif echo "$get_model" | grep -iq "F004"; then
  model="E5M"
fi

script_title() {
  case "$model" in
    K1) echo "$(t 'model.K1.title')" ;;
    K2PLUS) echo "$(t 'model.K2PLUS.title')" ;;
    3V3) echo "$(t 'model.3V3.title')" ;;
    3KE) echo "$(t 'model.3KE.title')" ;;
    10SE) echo "$(t 'model.10SE.title')" ;;
    E5M) echo "$(t 'model.E5M.title')" ;;
    *) echo "PRINTERS" ;;
  esac
}

main_menu_ui() {
  top_line
  title "$(format "$(t 'main.title')" "$(script_title)")" "${blue}"
  title "$(t 'main.copyright')" "${white}"
  inner_line
  title "$(t 'main.warning')" "${darkred}"
  inner_line
  hr
  main_menu_option '1' "$(t 'main.option.install')" "$(t 'main.option.menu')"
  main_menu_option '2' "$(t 'main.option.remove')" "$(t 'main.option.menu')"
  main_menu_option '3' "$(t 'main.option.customize')" "$(t 'main.option.menu')"
  main_menu_option '4' "$(t 'main.option.backup')" "$(t 'main.option.menu')"
  main_menu_option '5' "$(t 'main.option.tools')" "$(t 'main.option.menu')"
  main_menu_option '6' "$(t 'main.option.info')" "$(t 'main.option.menu')"
  main_menu_option '7' "$(t 'main.option.system')" "$(t 'main.option.menu')"
  main_menu_option '8' "$(t 'main.option.language')" "$(t 'main.option.menu')"
  hr
  inner_line
  hr
  bottom_menu_option 'q' "$(t 'menu.exit')" "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

main_menu() {
  clear
  main_menu_ui
  local main_menu_opt
  while true; do
    read -p "${white} $(t 'prompt.choice') ${yellow}" main_menu_opt
    case "${main_menu_opt}" in
      1) clear
         if [ "$model" = "K1" ]; then
           install_menu_k1
         elif [ "$model" = "K2PLUS" ]; then
           install_menu_k2plus
         elif [ "$model" = "3V3" ]; then
           install_menu_3v3
         elif [ "$model" = "3KE" ]; then
           install_menu_3ke
         elif [ "$model" = "E5M" ]; then
           install_menu_e5m
         else
           install_menu_10se
         fi
         break;;
      2) clear
         if [ "$model" = "K1" ]; then
           remove_menu_k1
         elif [ "$model" = "K2PLUS" ]; then
           remove_menu_k2plus
         elif [ "$model" = "3V3" ]; then
           remove_menu_3v3
         elif [ "$model" = "3KE" ]; then
           remove_menu_3ke
         elif [ "$model" = "E5M" ]; then
           remove_menu_e5m
         else
           remove_menu_10se
         fi
         break;;
      3) clear
         if [ "$model" = "K1" ]; then
           customize_menu_k1
         elif [ "$model" = "K2PLUS" ]; then
           customize_menu_k2plus
         elif [ "$model" = "3V3" ]; then
           customize_menu_3v3
         elif [ "$model" = "3KE" ]; then
           customize_menu_3ke
         elif [ "$model" = "E5M" ]; then
           customize_menu_e5m
         else
           customize_menu_10se
         fi
         break;;
      4) clear
         backup_restore_menu
         break;;
      5) clear
         if [ "$model" = "K1" ]; then
           tools_menu_k1
         elif [ "$model" = "K2PLUS" ]; then
           tools_menu_k2plus
         elif [ "$model" = "3V3" ]; then
           tools_menu_3v3
         elif [ "$model" = "3KE" ]; then
           tools_menu_3ke
         elif [ "$model" = "E5M" ]; then
           tools_menu_e5m
         else
           tools_menu_10se
         fi
         break;;
      6) clear
         if [ "$model" = "K1" ]; then
           info_menu_k1
         elif [ "$model" = "K2PLUS" ]; then
           info_menu_k2plus
         elif [ "$model" = "3V3" ]; then
           info_menu_3v3
         elif [ "$model" = "3KE" ]; then
           info_menu_3ke
         elif [ "$model" = "E5M" ]; then
           info_menu_e5m
         else
           info_menu_10se
         fi
         break;;
      7) clear
         system_menu
         break;;
      8) clear
         language_menu
         break;;
      Q|q)
         clear; exit 0;;
      *)
         error_msg "$(t 'menu.invalid_choice')";;
    esac
  done
  main_menu
}
