#!/bin/sh

set -e

function modern_cartographer_message() {
  top_line
  title 'Modern Cartographer' "${yellow}"
  inner_line
  hr
  echo -e " │ ${cyan}Installs the Cartographer3D plugin with K2PLUS patches and ${white}│"
  echo -e " │ ${cyan}updates configuration to use the modern probe stack.        ${white}│"
  hr
  bottom_line
}

function _modern_cartographer_require_k2plus() {
  if [ "$model" = "K2PLUS" ]; then
    return 0
  fi
  if [ -x /usr/bin/get_sn_mac.sh ]; then
    local model_raw
    model_raw=$(/usr/bin/get_sn_mac.sh model 2>/dev/null || true)
    case "$model_raw" in
      *F008*|*K2PLUS*|*k2plus*)
        return 0
        ;;
    esac
  fi
  echo "Error: Modern Cartographer is supported only on K2PLUS (F008)."
  return 1
}

function _modern_cartographer_python_bin() {
  local python_bin="/usr/share/klippy-env/bin/python"
  if [ -x "/mnt/UDISK/root/klippy-env/bin/python" ]; then
    python_bin="/mnt/UDISK/root/klippy-env/bin/python"
  elif [ ! -x "$python_bin" ]; then
    python_bin="$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)"
  fi
  if [ -z "$python_bin" ] || [ ! -x "$python_bin" ]; then
    echo "Error: Python not found."
    return 1
  fi
  echo "$python_bin"
}

function _modern_cartographer_backup_file() {
  local src="$1"
  local name="$2"
  if [ -f "$src" ]; then
    cp -f "$src" "${BACKUP_DIR}/${name}"
  else
    touch "${BACKUP_DIR}/${name}.missing"
  fi
}

function _modern_cartographer_restore_file() {
  local dest="$1"
  local name="$2"
  if [ -f "${BACKUP_DIR}/${name}" ]; then
    cp -f "${BACKUP_DIR}/${name}" "$dest"
  elif [ -f "${BACKUP_DIR}/${name}.missing" ]; then
    rm -f "$dest"
  fi
}

function _modern_cartographer_cleanup_old_extras() {
  rm -f "${KLIPPER_EXTRAS_FOLDER}/scanner.py" \
        "${KLIPPER_EXTRAS_FOLDER}/scanner.pyc" \
        "${KLIPPER_EXTRAS_FOLDER}/idm.py" \
        "${KLIPPER_EXTRAS_FOLDER}/idm.pyc" \
        "${KLIPPER_EXTRAS_FOLDER}/cartographer.pyc"
}

function _modern_cartographer_patch_mcu() {
  local python_bin="$1"
  local mcu_file="$2"
  "$python_bin" - "$mcu_file" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()
marker = "TRSYNC_SINGLE_MCU_TIMEOUT = 0.250\n\n"
insert = """# Compatibility shim for cartographer plugin.
class TriggerDispatch:
    def __init__(self, mcu):
        self._mcu = mcu
        ffi_main, ffi_lib = chelper.get_ffi()
        self._trdispatch = ffi_main.gc(ffi_lib.trdispatch_alloc(), ffi_lib.free)
        self._trsyncs = [MCU_trsync(mcu, self._trdispatch)]
        self._trigger_completion = None

    def add_stepper(self, stepper):
        trsyncs = {trsync.get_mcu(): trsync for trsync in self._trsyncs}
        trsync = trsyncs.get(stepper.get_mcu())
        if trsync is None:
            trsync = MCU_trsync(stepper.get_mcu(), self._trdispatch)
            self._trsyncs.append(trsync)
        trsync.add_stepper(stepper)
        # Check for unsupported multi-mcu shared stepper rails
        sname = stepper.get_name()
        if sname.startswith('stepper_'):
            for ot in self._trsyncs:
                for s in ot.get_steppers():
                    if ot is not trsync and s.get_name().startswith(sname[:9]):
                        cerror = self._mcu.get_printer().config_error
                        raise cerror('{"code": "key287", "msg": "Multi-mcu homing not supported on multi-mcu shared axis", "values":[]}')

    def get_steppers(self):
        return [s for trsync in self._trsyncs for s in trsync.get_steppers()]

    def get_oid(self):
        return self._trsyncs[0].get_oid()

    def start(self, print_time):
        reactor = self._mcu.get_printer().get_reactor()
        self._trigger_completion = reactor.completion()
        expire_timeout = TRSYNC_TIMEOUT
        if len(self._trsyncs) == 1:
            expire_timeout = TRSYNC_SINGLE_MCU_TIMEOUT
        for trsync in self._trsyncs:
            trsync.start(print_time, self._trigger_completion, expire_timeout)
        etrsync = self._trsyncs[0]
        ffi_main, ffi_lib = chelper.get_ffi()
        ffi_lib.trdispatch_start(self._trdispatch, etrsync.REASON_HOST_REQUEST)
        return self._trigger_completion

    def wait_end(self, home_end_time):
        etrsync = self._trsyncs[0]
        etrsync.set_home_end_time(home_end_time)
        if self._mcu.is_fileoutput():
            self._trigger_completion.complete(True)
        self._trigger_completion.wait()

    def stop(self):
        ffi_main, ffi_lib = chelper.get_ffi()
        ffi_lib.trdispatch_stop(self._trdispatch)
        res = [trsync.stop() for trsync in self._trsyncs]
        etrsync = self._trsyncs[0]
        if any([r == etrsync.REASON_COMMS_TIMEOUT for r in res]):
            return etrsync.REASON_COMMS_TIMEOUT
        return res[0]

"""
if "class TriggerDispatch" not in text:
    if marker not in text:
        raise SystemExit("Error: mcu.py marker not found")
    text = text.replace(marker, marker + insert)
else:
    block = text.split("class TriggerDispatch", 1)[1].split("class MCU_endstop", 1)[0]
    if "def get_steppers" not in block:
        text = text.replace(
            "    def get_oid(self):\n",
            "    def get_steppers(self):\n        return [s for trsync in self._trsyncs for s in trsync.get_steppers()]\n\n    def get_oid(self):\n",
        )
path.write_text(text)
print("Info: Patched mcu.py for Cartographer")
PY
}

function _modern_cartographer_ensure_pip() {
  local python_bin="$1"
  "$python_bin" - <<'PY'
import importlib.util
import subprocess
import sys
import urllib.request

if importlib.util.find_spec("pip") is None:
    print("Info: Installing pip for klippy-env...")
    try:
        subprocess.check_call([sys.executable, "-m", "ensurepip", "--upgrade"])
    except Exception:
        url = "https://bootstrap.pypa.io/get-pip.py"
        path = "/tmp/get-pip.py"
        print(f"Info: Downloading {url}")
        urllib.request.urlretrieve(url, path)
        subprocess.check_call([sys.executable, path])
else:
    print("Info: pip already available, skipping")
PY
}

function _modern_cartographer_install_plugin() {
  local python_bin="$1"
  "$python_bin" - <<'PY'
import importlib.util
import subprocess
import sys

if importlib.util.find_spec("cartographer") is None:
    print("Info: Installing cartographer3d-plugin...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "cartographer3d-plugin"])
else:
    print("Info: Cartographer plugin already installed, skipping")
PY
}


function _modern_cartographer_plugin_mcu_file() {
  local python_bin="$1"
  "$python_bin" - <<'PY'
import os
import cartographer

base = os.path.dirname(cartographer.__file__)
print(os.path.join(base, "adapters/klipper/mcu/mcu.py"))
PY
}

function _modern_cartographer_patch_plugin() {
  local python_bin="$1"
  "$python_bin" - <<'PY'
import os
import sys

try:
    import cartographer
except Exception as exc:
    print(f"Error: cartographer module not available: {exc}")
    sys.exit(1)

path = os.path.join(os.path.dirname(cartographer.__file__), "adapters/klipper/mcu/mcu.py")
text = open(path, "r").read()
old = "if result >= MCU_trsync.REASON_COMMS_TIMEOUT:"
new = "if result == MCU_trsync.REASON_COMMS_TIMEOUT:"
if old in text:
    text = text.replace(old, new, 1)
    with open(path, "w") as handle:
        handle.write(text)
    print("Info: Patched cartographer timeout check")
elif new in text:
    print("Info: Cartographer timeout check already patched")
else:
    print("Error: Could not locate cartographer timeout check")
    sys.exit(1)
PY
}

function _modern_cartographer_patch_stepper_z() {
  local python_bin="$1"
  local cfg_file="$2"
  "$python_bin" - "$cfg_file" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
lines = path.read_text().splitlines()
out = []
inside = False
found_endstop = False
found_retract = False

for line in lines:
    stripped = line.strip()
    if stripped.startswith('[stepper_z]'):
        inside = True
        found_endstop = False
        found_retract = False
        out.append(line)
        continue

    if inside and stripped.startswith('['):
        if not found_endstop:
            out.append('endstop_pin: probe:z_virtual_endstop')
        if not found_retract:
            out.append('homing_retract_dist: 0')
        inside = False

    if inside:
        key = stripped.split(':', 1)[0].split('=', 1)[0].strip()
        if key == 'endstop_pin':
            line = 'endstop_pin: probe:z_virtual_endstop'
            found_endstop = True
        elif key == 'homing_retract_dist':
            line = 'homing_retract_dist: 0'
            found_retract = True

    out.append(line)

if inside:
    if not found_endstop:
        out.append('endstop_pin: probe:z_virtual_endstop')
    if not found_retract:
        out.append('homing_retract_dist: 0')

path.write_text('\n'.join(out) + '\n')
print('Info: Patched stepper_z settings')
PY
}

function _modern_cartographer_remove_save_config_prtouch() {
  local python_bin="$1"
  local cfg_file="$2"
  "$python_bin" - "$cfg_file" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
lines = path.read_text().splitlines(True)
out = []
skip = False
for line in lines:
    if line.startswith('#*# [prtouch_v3]'):
        skip = True
        continue
    if skip:
        if line.startswith('#*# ['):
            skip = False
            out.append(line)
        continue
    out.append(line)

path.write_text(''.join(out))
print('Info: Removed prtouch_v3 save_config block (if present)')
PY
}

function _modern_cartographer_rollback() {
  echo "Error: install failed, rolling back changes"
  if [ -d "$BACKUP_DIR" ]; then
    _modern_cartographer_restore_file "$KLIPPER_KLIPPY_FOLDER/mcu.py" "mcu.py"
    _modern_cartographer_restore_file "$KLIPPER_EXTRAS_FOLDER/cartographer.py" "cartographer.py"
    _modern_cartographer_restore_file "$KLIPPER_EXTRAS_FOLDER/scanner.py" "scanner.py"
    _modern_cartographer_restore_file "$KLIPPER_EXTRAS_FOLDER/idm.py" "idm.py"
    _modern_cartographer_restore_file "$PRINTER_CFG" "printer.cfg"
    _modern_cartographer_restore_file "$CARTOGRAPHER_MODERN_CFG_FILE" "cartographer-modern.cfg"
    _modern_cartographer_restore_file "$HS_CONFIG_FOLDER/cartographer.cfg" "cartographer.cfg"
    if [ -n "${plugin_mcu_file:-}" ]; then
      _modern_cartographer_restore_file "$plugin_mcu_file" "cartographer-mcu.py"
    fi
  fi
}

function install_modern_cartographer_k2plus() {
  modern_cartographer_message
  local yn
  while true; do
    install_msg "Modern Cartographer" yn
    case "${yn}" in
      Y|y)
        echo -e "${white}"
        _modern_cartographer_require_k2plus || return

        local python_bin
        python_bin="$(_modern_cartographer_python_bin)"

        if [ ! -d "$HS_CONFIG_FOLDER" ]; then
          mkdir -p "$HS_CONFIG_FOLDER"
        fi

        BACKUP_DIR="${HS_BACKUP_FOLDER}/cartographer-modern-$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"

        local success=0
        trap 'if [ "$success" -eq 0 ]; then _modern_cartographer_rollback; fi' EXIT

        _modern_cartographer_backup_file "$KLIPPER_KLIPPY_FOLDER/mcu.py" "mcu.py"
        _modern_cartographer_backup_file "$KLIPPER_EXTRAS_FOLDER/cartographer.py" "cartographer.py"
        _modern_cartographer_backup_file "$KLIPPER_EXTRAS_FOLDER/scanner.py" "scanner.py"
        _modern_cartographer_backup_file "$KLIPPER_EXTRAS_FOLDER/idm.py" "idm.py"
        _modern_cartographer_backup_file "$PRINTER_CFG" "printer.cfg"
        _modern_cartographer_backup_file "$CARTOGRAPHER_MODERN_CFG_FILE" "cartographer-modern.cfg"
        _modern_cartographer_backup_file "$HS_CONFIG_FOLDER/cartographer.cfg" "cartographer.cfg"

        echo -e "Info: Installing Cartographer plugin..."
        _modern_cartographer_ensure_pip "$python_bin"
        _modern_cartographer_install_plugin "$python_bin"
        plugin_mcu_file="$(_modern_cartographer_plugin_mcu_file "$python_bin")"
        if [ -n "$plugin_mcu_file" ] && [ -f "$plugin_mcu_file" ]; then
          _modern_cartographer_backup_file "$plugin_mcu_file" "cartographer-mcu.py"
        fi
        _modern_cartographer_patch_plugin "$python_bin"

        echo -e "Info: Updating Klipper extras..."
        cp -f "$CARTOGRAPHER_MODERN_EXTRAS_URL" "$KLIPPER_EXTRAS_FOLDER/cartographer.py"
        chmod 644 "$KLIPPER_EXTRAS_FOLDER/cartographer.py"
        _modern_cartographer_cleanup_old_extras

        echo -e "Info: Patching Klipper system files..."
        _modern_cartographer_patch_mcu "$python_bin" "$KLIPPER_KLIPPY_FOLDER/mcu.py"

        echo -e "Info: Preparing configuration..."
        rm -f "$HS_CONFIG_FOLDER/cartographer.cfg"
        ln -sf "$CARTOGRAPHER_MODERN_CFG_URL" "$CARTOGRAPHER_MODERN_CFG_FILE"
        if grep -q "include Helper-Script/cartographer" "$PRINTER_CFG"; then
          sed -i '/include Helper-Script\/cartographer\.cfg/d' "$PRINTER_CFG"
        fi
        if ! grep -q "include Helper-Script/cartographer-modern" "$PRINTER_CFG"; then
          sed -i '/\[include printer_params\.cfg\]/a \[include Helper-Script/cartographer-modern\.cfg\]' "$PRINTER_CFG"
        fi
        _modern_cartographer_patch_stepper_z "$python_bin" "$PRINTER_CFG"
        _modern_cartographer_remove_save_config_prtouch "$python_bin" "$PRINTER_CFG"

        echo -e "Info: Restarting Klipper service..."
        restart_klipper

        success=1
        trap - EXIT
        ok_msg "Modern Cartographer has been installed successfully!"
        return;;
      N|n)
        error_msg "Installation canceled!"
        return;;
      *)
        error_msg "Please select a correct choice!";;
    esac
  done
}
