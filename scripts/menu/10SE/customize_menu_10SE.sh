#!/bin/sh

set -e

customize_menu_ui_10se() {
  top_line
  title "$(t 'section.customize.title')" "${yellow}"
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

customize_menu_10se() {
  clear
  customize_menu_ui_10se
  local customize_menu_opt
  while true; do
    read -p " ${white}$(t 'prompt.choice') ${yellow}" customize_menu_opt
    case "${customize_menu_opt}" in
      B|b)
        clear; main_menu; break;;
      Q|q)
         clear; exit 0;;
      *)
        error_msg "$(t 'menu.invalid_choice')";;
    esac
  done
  customize_menu_10se
}
