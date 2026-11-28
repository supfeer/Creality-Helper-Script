#!/bin/sh

set -e

tools_menu_ui_k2plus() {
  top_line
  title "$(t 'section.tools.title')" "${yellow}"
  inner_line
  hr
  subtitle "•$(t 'category.tools_maintenance.label'):"
  menu_option ' 1' "$(t 'item.fix_k2plus_homing_cfs_heartbeat.verb')" "$(t 'item.fix_k2plus_homing_cfs_heartbeat.label')"
  menu_option ' 2' "$(t 'item.fix_trsync_timeout.verb')" "$(t 'item.fix_trsync_timeout.label')"
  menu_option ' 3' "$(t 'item.install_k2_mainline_ota.verb')" "$(t 'item.install_k2_mainline_ota.label')"
  menu_option ' 4' "$(t 'item.check_k2_mainline_ota.verb')" "$(t 'item.check_k2_mainline_ota.label')"
  hr
  menu_option '14' 'Fix' 'Stepper too far in past on G28'
  hr
  inner_line
  hr
  bottom_menu_option 'b' "$(t 'menu.back')" "${yellow}"
  bottom_menu_option 'q' "$(t 'menu.exit')" "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

tools_menu_k2plus() {
  clear
  tools_menu_ui_k2plus
  local tools_menu_opt
  while true; do
    read -p " ${white}$(t 'prompt.choice') ${yellow}" tools_menu_opt
    case "${tools_menu_opt}" in
      1)
        run "fix_k2plus_homing_cfs_heartbeat" "tools_menu_ui_k2plus"
        ;;
      2)
        run "fix_trsync_timeout" "tools_menu_ui_k2plus"
        ;;
      3)
        run "install_k2_mainline_ota" "tools_menu_ui_k2plus"
        ;;
      4)
        run "check_k2_mainline_ota" "tools_menu_ui_k2plus"
        ;;
      B|b)
        clear; main_menu; break;;
      Q|q)
         clear; exit 0;;
      *)
        error_msg "$(t 'menu.invalid_choice')";;
    esac
  done
  tools_menu_k2plus
}
