#!/bin/sh

set -e

function useful_macros_message(){
  top_line
  title 'Useful Macros' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}It allows to use some usefull macros like Bed Leveling, PID, ${white}│"
  echo -e " │ ${cyan}stress test or backup and restore Klipper configurations     ${white}│"
  echo -e " │ ${cyan}files and Moonraker database.                                ${white}│"
  hr
  bottom_line
}

function install_useful_macros(){
  useful_macros_message
  local yn
  while true; do
    install_msg "Useful Macros" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        if [ -f "$HS_CONFIG_FOLDER"/useful-macros.cfg ]; then
          rm -f "$HS_CONFIG_FOLDER"/useful-macros.cfg
        fi
        if [ ! -d "$HS_CONFIG_FOLDER" ]; then
          mkdir -p "$HS_CONFIG_FOLDER"
        fi
        echo -e "Info: Linking file..."
        if [ "$model" = "K1" ]; then
          ln -sf "$USEFUL_MACROS_URL" "$HS_CONFIG_FOLDER"/useful-macros.cfg
        else
          ln -sf "$USEFUL_MACROS_3V3_URL" "$HS_CONFIG_FOLDER"/useful-macros.cfg
        fi
        if grep -q "include Helper-Script/useful-macros" "$PRINTER_CFG" ; then
          echo -e "Info: Useful Macros configurations are already enabled in printer.cfg file..."
        else
          echo -e "Info: Adding Useful Macros configurations in printer.cfg file..."
          sed -i '/\[include printer_params\.cfg\]/a \[include Helper-Script/useful-macros\.cfg\]' "$PRINTER_CFG"
        fi
        if [ "$model" = "K2PLUS" ]; then
          echo -e "Info: Linking K2PLUS macros..."
          ln -sf "$M191_MACRO_URL" "$HS_CONFIG_FOLDER"/m191.cfg
          ln -sf "$START_PRINT_MACRO_URL" "$HS_CONFIG_FOLDER"/start_print.cfg
          ln -sf "$BED_MESH_MACRO_URL" "$HS_CONFIG_FOLDER"/bed_mesh.cfg
          if [ -f "$HS_CONFIG_FOLDER"/overrides.cfg ]; then
            echo -e "Info: overrides.cfg already exists, keeping it..."
          else
            echo -e "Info: Copying overrides.cfg..."
            cp "$OVERRIDES_MACRO_URL" "$HS_CONFIG_FOLDER"/overrides.cfg
          fi
          if grep -q "include Helper-Script/m191" "$PRINTER_CFG" ; then
            echo -e "Info: M191 configurations are already enabled in printer.cfg file..."
          else
            echo -e "Info: Adding M191 configurations in printer.cfg file..."
            sed -i '/\[include printer_params\.cfg\]/a \[include Helper-Script/m191\.cfg\]' "$PRINTER_CFG"
          fi
          if grep -q "include Helper-Script/start_print" "$PRINTER_CFG" ; then
            echo -e "Info: Start Print configurations are already enabled in printer.cfg file..."
          else
            echo -e "Info: Adding Start Print configurations in printer.cfg file..."
            sed -i '/\[include printer_params\.cfg\]/a \[include Helper-Script/start_print\.cfg\]' "$PRINTER_CFG"
          fi
          if grep -q "include Helper-Script/bed_mesh" "$PRINTER_CFG" ; then
            echo -e "Info: Bed Mesh configurations are already enabled in printer.cfg file..."
          else
            echo -e "Info: Adding Bed Mesh configurations in printer.cfg file..."
            sed -i '/\[include printer_params\.cfg\]/a \[include Helper-Script/bed_mesh\.cfg\]' "$PRINTER_CFG"
          fi
          if grep -q "include Helper-Script/overrides" "$PRINTER_CFG" ; then
            echo -e "Info: Overrides configurations are already enabled in printer.cfg file..."
          else
            echo -e "Info: Adding Overrides configurations in printer.cfg file..."
            sed -i '/\[include printer_params\.cfg\]/a \[include Helper-Script/overrides\.cfg\]' "$PRINTER_CFG"
          fi
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Useful Macros have been installed successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}

function remove_useful_macros(){
  useful_macros_message
  local yn
  while true; do
    remove_msg "Useful Macros" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        echo -e "Info: Removing file..."
        rm -f "$HS_CONFIG_FOLDER"/useful-macros.cfg
        if grep -q "include Helper-Script/useful-macros" "$PRINTER_CFG" ; then
          echo -e "Info: Removing Useful Macros configurations in printer.cfg file..."
          sed -i '/include Helper-Script\/useful-macros\.cfg/d' "$PRINTER_CFG"
        else
          echo -e "Info: Useful Macros configurations are already removed in printer.cfg file..."
        fi
        rm -f "$HS_CONFIG_FOLDER"/m191.cfg
        rm -f "$HS_CONFIG_FOLDER"/start_print.cfg
        rm -f "$HS_CONFIG_FOLDER"/bed_mesh.cfg
        rm -f "$HS_CONFIG_FOLDER"/overrides.cfg
        if grep -q "include Helper-Script/m191" "$PRINTER_CFG" ; then
          echo -e "Info: Removing M191 configurations in printer.cfg file..."
          sed -i '/include Helper-Script\/m191\.cfg/d' "$PRINTER_CFG"
        fi
        if grep -q "include Helper-Script/start_print" "$PRINTER_CFG" ; then
          echo -e "Info: Removing Start Print configurations in printer.cfg file..."
          sed -i '/include Helper-Script\/start_print\.cfg/d' "$PRINTER_CFG"
        fi
        if grep -q "include Helper-Script/bed_mesh" "$PRINTER_CFG" ; then
          echo -e "Info: Removing Bed Mesh configurations in printer.cfg file..."
          sed -i '/include Helper-Script\/bed_mesh\.cfg/d' "$PRINTER_CFG"
        fi
        if grep -q "include Helper-Script/overrides" "$PRINTER_CFG" ; then
          echo -e "Info: Removing Overrides configurations in printer.cfg file..."
          sed -i '/include Helper-Script\/overrides\.cfg/d' "$PRINTER_CFG"
        fi
        if [ ! -n "$(ls -A "$HS_CONFIG_FOLDER")" ]; then
          rm -rf "$HS_CONFIG_FOLDER"
        fi
        echo -e "Info: Restarting Klipper service..."
        restart_klipper
        ok_msg "Useful Macros have been removed successfully!"
        return;;
      N|n)
        error_msg "Deletion canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}