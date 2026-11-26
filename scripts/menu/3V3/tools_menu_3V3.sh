#!/bin/sh

set -e

tools_menu_ui_3v3() {
  top_line
  title "$(t 'section.tools.title')" "${yellow}"
  inner_line
  hr
  inner_line
  hr
  bottom_menu_option 'b' "$(t 'menu.back')" "${yellow}"
  bottom_menu_option 'q' "$(t 'menu.exit')" "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

tools_menu_3v3() {
  clear
  tools_menu_ui_3v3
  local tools_menu_opt
  while true; do
    read -p " ${white}$(t 'prompt.choice') ${yellow}" tools_menu_opt
    case "${tools_menu_opt}" in
      B|b)
        clear; main_menu; break;;
      Q|q)
         clear; exit 0;;
      *)
        error_msg "$(t 'menu.invalid_choice')";;
    esac
  done
  tools_menu_3v3
}
