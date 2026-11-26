#!/bin/sh

set -e

function backup_klipper_config_files_message(){
  top_line
  title 'Backup Klipper configuration files' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}This allows to backup Klipper configuration files in a       ${white}│"
  echo -e " │ ${cyan}backup_config.tar.gz compressed file.                        ${white}│"
  hr
  bottom_line
}

function restore_klipper_config_files_message(){
  top_line
  title 'Restore Klipper configuration files' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}This allows to restore Klipper configuration files from a    ${white}│"
  echo -e " │ ${cyan}backup_config.tar.gz compressed file.                        ${white}│"
  hr
  bottom_line
}

function backup_klipper_config_files(){
  backup_klipper_config_files_message
  local yn
  while true; do
    backup_msg "Klipper configuration files" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if [ -f "$KLIPPER_CONFIG_FOLDER"/backup_config.tar.gz ]; then
          rm -f "$KLIPPER_CONFIG_FOLDER"/backup_config.tar.gz
        fi
        cd "$PRINTER_DATA_FOLDER"
        echo -e "Info: Compressing files..."
        rm -f "$PRINTER_DATA_FOLDER"/backup_config.tar.gz.tmp
        tar -czvf "$PRINTER_DATA_FOLDER"/backup_config.tar.gz.tmp config
        mv "$PRINTER_DATA_FOLDER"/backup_config.tar.gz.tmp "$KLIPPER_CONFIG_FOLDER"/backup_config.tar.gz
        ok_msg "Klipper configuration files have been saved successfully in ${yellow}${KLIPPER_CONFIG_FOLDER} ${green}folder!"
        return;;
      N|n)
        error_msg "Backup canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function restore_klipper_config_files(){
  restore_klipper_config_files_message
  local yn
  while true; do
    restore_msg "Klipper configuration files" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        cd "$PRINTER_DATA_FOLDER"
        if [ ! -f config/backup_config.tar.gz ] && [ ! -f backup_config.tar.gz ]; then
          error_msg "Backup archive backup_config.tar.gz not found! Restoration canceled."
          return 1
        fi
        if [ -f config/backup_config.tar.gz ]; then
          mv config/backup_config.tar.gz backup_config.tar.gz
        fi
        if ! tar -tzf backup_config.tar.gz >/dev/null 2>&1; then
          error_msg "Backup archive backup_config.tar.gz is invalid! Restoration canceled."
          return 1
        fi
        if [ -d config ]; then
          rm -rf config
        fi
        echo -e "Info: Restoring files..."
        tar -xvf backup_config.tar.gz
        mv backup_config.tar.gz config/backup_config.tar.gz
        ok_msg "Klipper configuration files have been restored successfully!"
        return;;
      N|n)
        error_msg "Restoration canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}