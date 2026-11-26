#!/bin/sh

set -e

install_menu_ui_k2plus() {
  top_line
  title "$(t 'section.install.title')" "${yellow}"
  inner_line
  hr
  subtitle "•$(t 'category.install_essentials.label'):"
  menu_option ' 1' "$(t 'item.install_moonraker_nginx.verb')" "$(t 'item.install_moonraker_nginx.label')"
  menu_option ' 2' "$(t 'item.install_fluidd.verb')" "$(t 'item.install_fluidd.label')"
  menu_option ' 3' "$(t 'item.install_mainsail.verb')" "$(t 'item.install_mainsail.label')"
  hr
  subtitle "•$(t 'category.install_utilities.label'):"
  menu_option ' 4' "$(t 'item.install_entware.verb')" "$(t 'item.install_entware.label')"
  menu_option ' 5' "$(t 'item.install_gcode_shell_command.verb')" "$(t 'item.install_gcode_shell_command.label')"
  hr
  subtitle "•$(t 'category.install_improvements.label'):"
  menu_option ' 6' "$(t 'item.install_kamp.verb')" "$(t 'item.install_kamp.label')"
  menu_option ' 7' "$(t 'item.install_buzzer_support.verb')" "$(t 'item.install_buzzer_support.label')"
  menu_option ' 8' "$(t 'item.install_nozzle_cleaning_fan_control.verb')" "$(t 'item.install_nozzle_cleaning_fan_control.label')"
  menu_option ' 9' "$(t 'item.install_fans_control_macros.verb')" "$(t 'item.install_fans_control_macros.label')"
  menu_option '10' "$(t 'item.install_improved_shapers.verb')" "$(t 'item.install_improved_shapers.label')"
  menu_option '11' "$(t 'item.install_useful_macros.verb')" "$(t 'item.install_useful_macros.label')"
  menu_option '12' "$(t 'item.install_save_zoffset.verb')" "$(t 'item.install_save_zoffset.label')"
  menu_option '13' "$(t 'item.install_screws_tilt_adjust.verb')" "$(t 'item.install_screws_tilt_adjust.label')"
  menu_option '14' "$(t 'item.install_m600.verb')" "$(t 'item.install_m600.label')"
  menu_option '15' "$(t 'item.install_git_backup.verb')" "$(t 'item.install_git_backup.label')"
  menu_option '16' "$(t 'item.install_modern_cartographer_k2plus.verb')" "$(t 'item.install_modern_cartographer_k2plus.label')"
  hr
  subtitle "•$(t 'category.install_camera.label'):"
  menu_option '17' "$(t 'item.install_moonraker_timelapse.verb')" "$(t 'item.install_moonraker_timelapse.label')"
  menu_option '18' "$(t 'item.install_camera_settings.verb')" "$(t 'item.install_camera_settings.label')"
  menu_option '19' "$(t 'item.install_usb_camera.verb')" "$(t 'item.install_usb_camera.label')"
  hr
  subtitle "•$(t 'category.install_remote_access.label'):"
  menu_option '20' "$(t 'item.install_octoeverywhere.verb')" "$(t 'item.install_octoeverywhere.label')"
  menu_option '21' "$(t 'item.install_moonraker_obico.verb')" "$(t 'item.install_moonraker_obico.label')"
  menu_option '22' "$(t 'item.install_guppyflo.verb')" "$(t 'item.install_guppyflo.label')"
  menu_option '23' "$(t 'item.install_mobileraker_companion.verb')" "$(t 'item.install_mobileraker_companion.label')"
  menu_option '24' "$(t 'item.install_octoapp_companion.verb')" "$(t 'item.install_octoapp_companion.label')"
  menu_option '25' "$(t 'item.install_simplyprint.verb')" "$(t 'item.install_simplyprint.label')"
  hr
  inner_line
  hr
  bottom_menu_option 'b' "$(t 'menu.back')" "${yellow}"
  bottom_menu_option 'q' "$(t 'menu.exit')" "${darkred}"
  hr
  version_line "$(get_script_version)"
  bottom_line
}

install_menu_k2plus() {
  clear
  install_menu_ui_k2plus
  local install_menu_opt
  while true; do
    read -p " ${white}$(t 'prompt.choice') ${yellow}" install_menu_opt
    case "${install_menu_opt}" in
      1)
        if [ -d "$MOONRAKER_FOLDER" ]; then  
          error_msg "Moonraker and Nginx are already installed!"
        else
          run "install_moonraker_nginx" "install_menu_ui_k2plus"
        fi
        
        ;;
      2)
        if [ -d "$FLUIDD_FOLDER" ]; then  
          error_msg "Fluidd is already installed!"
        elif [ ! -d "$MOONRAKER_FOLDER" ] && [ ! -d "$NGINX_FOLDER" ]; then
          error_msg "Moonraker and Nginx are needed, please install them first!"
        else
          run "install_fluidd" "install_menu_ui_k2plus"
        fi
        
        ;;
      3)
        if [ -d "$MAINSAIL_FOLDER" ]; then  
          error_msg "Mainsail is already installed!"
        elif [ ! -d "$MOONRAKER_FOLDER" ] && [ ! -d "$NGINX_FOLDER" ]; then
          error_msg "Moonraker and Nginx are needed, please install them first!"
        else
          run "install_mainsail" "install_menu_ui_k2plus"
        fi
        
        ;;
      4)
        if [ -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is already installed!"
        else
          run "install_entware" "install_menu_ui_k2plus"
        fi
        
        ;;
      5)
        if [ -f "$KLIPPER_SHELL_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is already installed!"
        else
          run "install_gcode_shell_command" "install_menu_ui_k2plus"
        fi
        
        ;;
      6)
        if [ -d "$KAMP_FOLDER" ]; then
          error_msg "Klipper Adaptive Meshing & Purging is already installed!"
        else
          run "install_kamp" "install_menu_ui_k2plus"
        fi
        
        ;;
      7)
        if [ -f "$BUZZER_FILE" ]; then
          error_msg "Buzzer Support is already installed!"
        elif [ ! -f "$KLIPPER_SHELL_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed, please install it first!"
        else
          run "install_buzzer_support" "install_menu_ui_k2plus"
        fi
        
        ;;
      8)
        if [ -d "$NOZZLE_CLEANING_FOLDER" ]; then
          error_msg "Nozzle Cleaning Fan Control is already installed!"
        else
          run "install_nozzle_cleaning_fan_control" "install_menu_ui_k2plus"
        fi
        
        ;;
      9)
        if [ -f "$FAN_CONTROLS_FILE" ]; then
          error_msg "Fans Control Macros are already installed!"
        else
          run "install_fans_control_macros" "install_menu_ui_k2plus"
        fi
        
        ;;
      10)
        if [ -d "$IMP_SHAPERS_FOLDER" ]; then
          error_msg "Improved Shapers Calibrations are already installed!"
        elif [ -d "$GUPPY_SCREEN_FOLDER" ]; then
          error_msg "Guppy Screen already has these features!"
        elif [ ! -f "$KLIPPER_SHELL_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed, please install it first!"
        else
          run "install_improved_shapers" "install_menu_ui_k2plus"
        fi
        
        ;;
      11)
        if [ -f "$USEFUL_MACROS_FILE" ]; then
          error_msg "Useful Macros are already installed!"
        elif [ ! -f "$KLIPPER_SHELL_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed, please install it first!"
        else
          run "install_useful_macros" "install_menu_ui_k2plus"
        fi
        
        ;;
      12)
        if [ -f "$SAVE_ZOFFSET_FILE" ]; then
          error_msg "Save Z-Offset Macros are already installed!"
        else
          run "install_save_zoffset_macros" "install_menu_ui_k2plus"
        fi
        
        ;;
      13)
        if [ -f "$SCREWS_ADJUST_FILE" ]; then
          error_msg "Screws Tilt Adjust Support is already installed!"
        else
          run "install_screws_tilt_adjust" "install_menu_ui_k2plus"
        fi
        
        ;;
      14)
        if [ -f "$M600_SUPPORT_FILE" ]; then
          error_msg "M600 Support is already installed!"
        else
          run "install_m600_support" "install_menu_ui_k2plus"
        fi
        
        ;;
      15)
        if [ -f "$GIT_BACKUP_FILE" ]; then
          error_msg "Git Backup is already installed!"
        elif [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is needed, please install it first!"
        elif [ ! -f "$KLIPPER_SHELL_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed, please install it first!"
        else
          run "install_git_backup" "install_menu_ui_k2plus"
        fi
        
        ;;
      16)
        if [ -f "$CARTOGRAPHER_MODERN_CFG_FILE" ] && [ -f "$KLIPPER_EXTRAS_FOLDER/cartographer.py" ]; then
          error_msg "Modern Cartographer is already installed!"
        else
          run "install_modern_cartographer_k2plus" "install_menu_ui_k2plus"
        fi
        
        ;;
      17)
        if [ -f "$TIMELAPSE_FILE" ]; then
          error_msg "Moonraker Timelapse is already installed!"
        elif [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is needed, please install it first!"
        else
          run "install_moonraker_timelapse" "install_menu_ui_k2plus"
        fi
        
        ;;
      18)
        if [ -f "$CAMERA_SETTINGS_FILE" ]; then
          error_msg "Camera Settings Control is already installed!"
        elif v4l2-ctl --list-devices | grep -q 'CCX2F3299' && [ ! -f "$INITD_FOLDER"/S50usb_camera ]; then
          error_msg "This is not compatible with the new hardware version of the camera!"
        elif [ ! -f "$KLIPPER_SHELL_FILE" ]; then
          error_msg "Klipper Gcode Shell Command is needed, please install it first!"
        else
          run "install_camera_settings_control" "install_menu_ui_k2plus"
        fi
        
        ;;
      19)
        if [ -f "$USB_CAMERA_FILE" ]; then
          error_msg "Camera USB Support is already installed!"
        elif [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is needed, please install it first!"
        else
          run "install_usb_camera" "install_menu_ui_k2plus"
        fi
        
        ;;
      20)
        if [ ! -d "$MOONRAKER_FOLDER" ]; then
          error_msg "Moonraker and Nginx are needed, please install them first!"
        elif [ ! -d "$FLUIDD_FOLDER" ] && [ ! -d "$MAINSAIL_FOLDER" ]; then
          error_msg "Fluidd or Mainsail is needed, please install one of them first!"
        elif [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is needed, please install it first!"
        else
          run "install_octoeverywhere" "install_menu_ui_k2plus"
        fi
        
        ;;
      21)
        if [ ! -d "$MOONRAKER_FOLDER" ]; then
          error_msg "Moonraker and Nginx are needed, please install them first!"
        elif [ ! -d "$FLUIDD_FOLDER" ] && [ ! -d "$MAINSAIL_FOLDER" ]; then
          error_msg "Fluidd or Mainsail is needed, please install one of them first!"
        elif [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is needed, please install it first!"
        else
          run "install_moonraker_obico" "install_menu_ui_k2plus"
        fi
        
        ;;
      22)
        if [ ! -d "$MOONRAKER_FOLDER" ] && [ ! -d "$NGINX_FOLDER" ]; then
          error_msg "Moonraker and Nginx are needed, please install them first!"
        else
          run "install_guppyflo" "install_menu_ui_k2plus"
        fi
        
        ;;
      23)
        if [ -d "$MOBILERAKER_COMPANION_FOLDER" ]; then
          error_msg "Mobileraker Companion is already installed!"
        elif [ ! -d "$MOONRAKER_FOLDER" ]; then
          error_msg "Moonraker and Nginx are needed, please install them first!"
        elif [ ! -d "$FLUIDD_FOLDER" ] && [ ! -d "$MAINSAIL_FOLDER" ]; then
          error_msg "Fluidd or Mainsail is needed, please install one of them first!"
        elif [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is needed, please install it first!"
        else
          run "install_mobileraker_companion" "install_menu_ui_k2plus"
        fi
        
        ;;
      24)
        if [ -d "$OCTOAPP_COMPANION_FOLDER" ]; then
          error_msg "OctoApp Companion is already installed!"
        elif [ ! -d "$MOONRAKER_FOLDER" ]; then
          error_msg "Moonraker and Nginx are needed, please install them first!"
        elif [ ! -d "$FLUIDD_FOLDER" ] && [ ! -d "$MAINSAIL_FOLDER" ]; then
          error_msg "Fluidd or Mainsail is needed, please install one of them first!"
        elif [ ! -f "$ENTWARE_FILE" ]; then
          error_msg "Entware is needed, please install it first!"
        else
          run "install_octoapp_companion" "install_menu_ui_k2plus"
        fi
        
        ;;
      25)
        if grep -q "\[simplyprint\]" "$MOONRAKER_CFG"; then
          error_msg "SimplyPrint is already installed!"
        elif [ ! -d "$MOONRAKER_FOLDER" ]; then
          error_msg "Moonraker and Nginx are needed, please install them first!"
        elif [ ! -d "$FLUIDD_FOLDER" ] && [ ! -d "$MAINSAIL_FOLDER" ]; then
          error_msg "Fluidd or Mainsail is needed, please install one of them first!"
        else
          run "install_simplyprint" "install_menu_ui_k2plus"
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
  install_menu_k2plus
}
