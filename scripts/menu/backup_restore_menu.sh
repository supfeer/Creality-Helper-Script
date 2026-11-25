#!/bin/sh

set -e

backup_restore_menu_ui() {
  top_line
  title "$(t 'section.backup.title')" "${yellow}"
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

backup_restore_menu() {
  clear
  backup_restore_menu_ui
  local backup_restore_menu_opt
  while true; do
    read -p " ${white}$(t 'prompt.choice') ${yellow}" backup_restore_menu_opt
    case "${backup_restore_menu_opt}" in
      B|b)
        clear; main_menu; break;;
      Q|q)
         clear; exit 0;;
      *)
        error_msg "$(t 'menu.invalid_choice')";;
    esac
  done
  backup_restore_menu
}
