#!/bin/sh

set -e

language_menu_ui() {
  top_line
  title "$(t 'section.language.title')" "${yellow}"
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

language_menu() {
  clear
  language_menu_ui
  local language_menu_opt
  while true; do
    read -p " ${white}$(t 'prompt.choice') ${yellow}" language_menu_opt
    case "${language_menu_opt}" in
      B|b)
        clear; main_menu; break;;
      Q|q)
         clear; exit 0;;
      *)
        error_msg "$(t 'menu.invalid_choice')";;
    esac
  done
  language_menu
}
