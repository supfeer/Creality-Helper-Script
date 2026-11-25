#!/bin/sh

set -e

remove_menu_ui_3v3() {
  top_line
  title "$(t 'section.remove.title')" "${yellow}"
  inner_line
  hr
  subtitle "•$(t 'category.remove_essentials.label'):"
  menu_option ' 1' "$(t 'item.remove_mainsail.verb')" "$(t 'item.remove_mainsail.label')"
  menu_option ' 2' "$(t 'item.remove_moonraker_3v3.verb')" "$(t 'item.remove_moonraker_3v3.label')"
  menu_option ' 3' "$(t 'item.remove_fluidd_3v3.verb')" "$(t 'item.remove_fluidd_3v3.label')"
  hr
  subtitle "•$(t 'category.remove_utilities.label'):"
  menu_option ' 4' "$(t 'item.remove_entware.verb')" "$(t 'item.remove_entware.label')"
  menu_option ' 5' "$(t 'item.remove_gcode_shell_command.verb')" "$(t 'item.remove_gcode_shell_command.label')"
  hr
  subtitle "•$(t 'category.remove_improvements.label'):"
  menu_option ' 6' "$(t 'item.remove_kamp.verb')" "$(t 'item.remove_kamp.label')"
  menu_option ' 7' "$(t 'item.remove_buzzer_support.verb')" "$(t 'item.remove_buzzer_support.label')"
  menu_option ' 8' "$(t 'item.remove_improved_shapers.verb')" "$(t 'item.remove_improved_shapers.label')"
  menu_option ' 9' "$(t 'item.remove_useful_macros.verb')" "$(t 'item.remove_useful_macros.label')"
  menu_option '10' "$(t 'item.remove_save_zoffset.verb')" "$(t 'item.remove_save_zoffset.label')"
  menu_option '11' "$(t 'item.remove_m600.verb')" "$(t 'item.remove_m600.label')"
  menu_option '12' "$(t 'item.remove_git_backup.verb')" "$(t 'item.remove_git_backup.label')"
  hr
  subtitle "•$(t 'category.remove_camera.label'):"
  menu_option '13' "$(t 'item.remove_moonraker_timelapse.verb')" "$(t 'item.remove_moonraker_timelapse.label')"
  menu_option '14' "$(t 'item.remove_camera_settings.verb')" "$(t 'item.remove_camera_settings.label.3V3')"
  menu_option '15' "$(t 'item.remove_usb_camera.verb')" "$(t 'item.remove_usb_camera.label')"
  hr
  subtitle "•$(t 'category.remove_remote_access.label'):"
  menu_option '16' "$(t 'item.remove_octoeverywhere.verb')" "$(t 'item.remove_octoeverywhere.label')"
  menu_option '17' "$(t 'item.remove_moonraker_obico.verb')" "$(t 'item.remove_moonraker_obico.label')"
  menu_option '18' "$(t 'item.remove_guppyflo.verb')" "$(t 'item.remove_guppyflo.label')"
  menu_option '19' "$(t 'item.remove_mobileraker_companion.verb')" "$(t 'item.remove_mobileraker_companion.label')"
  menu_option '20' "$(t 'item.remove_octoapp_companion.verb')" "$(t 'item.remove_octoapp_companion.label')"
  menu_option '21' "$(t 'item.remove_simplyprint.verb')" "$(t 'item.remove_simplyprint.label')"
  hr
  inner_line
  hr
  bottom_menu_option 'b' "$(t 'menu.back')" "${yellow}"
  bottom_menu_option 'q' "$(t 'menu.exit')" "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

remove_menu_3v3() {
  clear
  remove_menu_ui_3v3
  local remove_menu_opt
  while true; do
    read -p " ${white}$(t 'prompt.choice') ${yellow}" remove_menu_opt
    case "${remove_menu_opt}" in
      1)
        if [ ! -d "$MAINSAIL_FOLDER" ]; then
          error_msg "Mainsail is not installed!"
        elif [ ! -f "$CREALITY_WEB_FILE" ] && [ ! -d "$FLUIDD_FOLDER" ]; then
          error_msg "Creality Web Interface is removed!"
          echo -e " ${darkred}Please restore Creality Web Interface first if you want to remove Mainsail.${white}"
          echo
        else
          run "remove_mainsail" "remove_menu_ui_3v3"
        fi
        
        ;;
      2)
        if [ ! -d "$MOONRAKER_FOLDER" ]; then
          error_msg "Updated Moonraker is not installed!"
        else
         run "remove_moonraker_3v3" "remove_menu_ui_3v3"
        fi
        
        ;;
      3)
        if [ ! -d "$FLUIDD_FOLDER" ]; then
          error_msg "Updated Fluidd is not installed!"
        elif [ ! -f "$CREALITY_WEB_FILE" ] && [ ! -d "$MAINSAIL_FOLDER" ]; then
          error_msg "Creality Web Interface is removed!"
          echo -e " ${darkred}Please restore Creality Web Interface first if you want to remove Updated Fluidd.${white}"
          echo
        else
          run "remove_fluidd_3v3" "remove_menu_ui_3v3"
        fi
        
        ;;
      4)
        if [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is not installed!"
        elif [ -f "$TIMELAPSE_FILE" ]; then
          error_msg "Entware is needed to use Moonraker Timelapse, please uninstall it first!"
        elif [ -f "$GIT_BACKUP_FILE" ]; then
          error_msg "Entware is needed to use Git Backup, please uninstall it first!"
        elif [ -d "$OCTOEVERYWHERE_FOLDER" ]; then
          error_msg "Entware is needed to use OctoEverywhere, please uninstall it first!"
        elif [ -d "$MOONRAKER_OBICO_FOLDER" ]; then
          error_msg "Entware is needed to use Moonraker Obico, please uninstall it first!"
        elif [ -f "$USB_CAMERA_FILE" ]; then
          error_msg "Entware is needed to use USB Camera Support, please uninstall it first!"
        else
          run "remove_entware" "remove_menu_ui_3v3"
        fi
        
        ;;
      5)
        if [ ! -f "$KLIPPER_SHELL_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is not installed!"
        elif [ -d "$GUPPY_SCREEN_FOLDER" ]; then
          error_msg "Klipper Gcode Shell Command is needed to use Guppy Screen, please uninstall it first!"
        elif [ -d "$IMP_SHAPERS_FOLDER" ]; then
          error_msg "Klipper Gcode Shell Command is needed to use Improved Shapers Calibrations, please uninstall it first!"
        elif [ -f "$GIT_BACKUP_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed to use Git Backup, please uninstall it first!"
        else
          run "remove_gcode_shell_command" "remove_menu_ui_3v3"
        fi
        
        ;;
      6)
        if [ ! -d "$KAMP_FOLDER" ]; then
          error_msg "Klipper Adaptive Meshing & Purging is not installed!"
        else
          run "remove_kamp" "remove_menu_ui_3v3"
        fi
        
        ;;
      7)
        if [ ! -f "$BUZZER_FILE" ]; then
          error_msg "Buzzer Support is not installed!"
        else
          run "remove_buzzer_support" "remove_menu_ui_3v3"
        fi
        
        ;;
      8)
        if [ ! -d "$IMP_SHAPERS_FOLDER" ]; then
          error_msg "Improved Shapers Calibrations are not installed!"
        else
          run "remove_improved_shapers" "remove_menu_ui_3v3"
        fi
        
        ;;
      9)
        if [ ! -f "$USEFUL_MACROS_FILE" ]; then
          error_msg "Useful Macros are not installed!"
        else
          run "remove_useful_macros" "remove_menu_ui_3v3"
        fi
        
        ;;
      10)
        if [ ! -f "$SAVE_ZOFFSET_FILE" ]; then
          error_msg "Save Z-Offset Macros are not installed!"
        else
          run "remove_save_zoffset_macros" "remove_menu_ui_3v3"
        fi
        
        ;;
      11)
        if [ ! -f "$M600_SUPPORT_FILE" ]; then
          error_msg "M600 Support is not installed!"
        else
          run "remove_m600_support" "remove_menu_ui_3v3"
        fi
        
        ;;
      12)
        if [ ! -f "$GIT_BACKUP_FILE" ]; then
          error_msg "Git Backup is not installed!"
        else
          run "remove_git_backup" "remove_menu_ui_3v3"
        fi
        
        ;;
      13)
        if [ ! -f "$TIMELAPSE_FILE" ]; then
          error_msg "Moonraker Timelapse is not installed!"
        else
          run "remove_moonraker_timelapse" "remove_menu_ui_3v3"
        fi
        
        ;;
      14)
        if [ ! -f "$CAMERA_SETTINGS_FILE" ]; then
          error_msg "Nebula Camera Settings Control is not installed!"
        else
          run "remove_camera_settings_control" "remove_menu_ui_3v3"
        fi
        
        ;;
      15)
        if [ ! -f "$USB_CAMERA_FILE" ]; then
          error_msg "USB Camera Support is not installed!"
        else
          run "remove_usb_camera" "remove_menu_ui_3v3"
        fi
        
        ;;
      16)
        if [ ! -d "$OCTOEVERYWHERE_FOLDER" ]; then
          error_msg "OctoEverywhere is not installed!"
        else
          run "remove_octoeverywhere" "remove_menu_ui_3v3"
        fi
        
        ;;
      17)
        if [ ! -d "$MOONRAKER_OBICO_FOLDER" ]; then
          error_msg "Moonraker Obico is not installed!"
        else
          run "remove_moonraker_obico" "remove_menu_ui_3v3"
        fi
        
        ;;
      18)
        if [ ! -d "$GUPPYFLO_FOLDER" ]; then
          error_msg "GuppyFLO is not installed!"
        else
          run "remove_guppyflo" "remove_menu_ui_3v3"
        fi
        
        ;;
      19)
        if [ ! -d "$MOBILERAKER_COMPANION_FOLDER" ]; then
          error_msg "Mobileraker Companion is not installed!"
        else
          run "remove_mobileraker_companion" "remove_menu_ui_3v3"
        fi
        
        ;;
      20)
        if [ ! -d "$OCTOAPP_COMPANION_FOLDER" ]; then
          error_msg "OctoApp Companion is not installed!"
        else
          run "remove_octoapp_companion" "remove_menu_ui_3v3"
        fi
        
        ;;
      21)
        if ! grep -q "\[simplyprint\]" "$MOONRAKER_CFG"; then
          error_msg "SimplyPrint is not installed!"
        else
          run "remove_simplyprint" "remove_menu_ui_3v3"
        fi
        
        ;;
      B|b)
        clear; main_menu; break;;
      Q|q)
         clear; exit 0;;
      *)
        error_msg "$(t 'menu.invalid_choice')";;
    esac
  done
  remove_menu_3v3
}
