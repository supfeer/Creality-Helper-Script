#!/bin/sh

set -e

info_menu_ui_k1() {
  top_line
  title "$(t 'section.info.title')" "${yellow}"
  inner_line
  hr
  subtitle "•$(t 'category.info_essentials.label'):"
  info_line "$(check_dir "")" "$(t 'item.info_moonraker_nginx.label')"
  info_line "$(check_dir "")" "$(t 'item.info_fluidd.label')"
  info_line "$(check_dir "")" "$(t 'item.info_mainsail.label')"
  hr
  subtitle "•$(t 'category.info_utilities.label'):"
  info_line "$(check_file "")" "$(t 'item.info_entware.label')"
  info_line "$(check_file "")" "$(t 'item.info_klipper_gcode_shell_command.label')"
  hr
  subtitle "•$(t 'category.info_improvements.label'):"
  info_line "$(check_dir "")" "$(t 'item.info_klipper_adaptive_meshing_purging.label')"
  info_line "$(check_file "")" "$(t 'item.info_buzzer_support.label')"
  info_line "$(check_dir "")" "$(t 'item.info_nozzle_cleaning_fan_control.label')"
  info_line "$(check_file "")" "$(t 'item.info_fans_control_macros.label')"
  info_line "$(check_dir "")" "$(t 'item.info_improved_shapers_calibrations.label')"
  info_line "$(check_file "")" "$(t 'item.info_useful_macros.label')"
  info_line "$(check_file "")" "$(t 'item.info_save_z_offset_macros.label')"
  info_line "$(check_file "")" "$(t 'item.info_screws_tilt_adjust_support.label')"
  info_line "$(check_file "")" "$(t 'item.info_m600_support.label')"
  info_line "$(check_file "")" "$(t 'item.info_git_backup.label')"
  hr
  subtitle "•$(t 'category.info_camera.label'):"
  info_line "$(check_file "")" "$(t 'item.info_moonraker_timelapse.label')"
  info_line "$(check_file "")" "$(t 'item.info_camera_settings_control.label')"
  info_line "$(check_file "")" "$(t 'item.info_usb_camera_support.label')"
  hr
  subtitle "•$(t 'category.info_remote_access.label'):"
  info_line "$(check_dir "")" "$(t 'item.info_octoeverywhere.label')"
  info_line "$(check_dir "")" "$(t 'item.info_obico.label')"
  info_line "$(check_dir "")" "$(t 'item.info_guppyflo.label')"
  info_line "$(check_dir "")" "$(t 'item.info_mobileraker_companion.label')"
  info_line "$(check_dir "")" "$(t 'item.info_octoapp_companion.label')"
  info_line "$(check_simplyprint)" "$(t 'item.info_simplyprint.label')"
  hr
  subtitle "•$(t 'category.info_customization.label'):"
  info_line "$(check_file "")" "$(t 'item.info_custom_boot_display.label')"
  info_line "$(check_file "")" "$(t 'item.info_creality_web_interface.label')"
  info_line "$(check_dir "")" "$(t 'item.info_guppy_screen.label')"
  info_line "$(check_file "")" "$(t 'item.info_creality_dynamic_logos_for_fluidd.label')"
  hr
  inner_line
  hr
  bottom_menu_option 'b' "$(t 'menu.back')" "${yellow}"
  bottom_menu_option 'q' "$(t 'menu.exit')" "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

info_menu_k1() {
  clear
  info_menu_ui_k1
  local info_menu_opt
  while true; do
    read -p " ${white}$(t 'prompt.choice') ${yellow}" info_menu_opt
    case "${info_menu_opt}" in
      B|b)
        clear; main_menu; break;;
      Q|q)
         clear; exit 0;;
      *)
         error_msg "$(t 'menu.invalid_choice')";;
    esac
  done
  info_menu_k1
}
