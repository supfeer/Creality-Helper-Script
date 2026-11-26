#!/bin/sh
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# 1. Syntax check every shell script in Creality-Helper-Script.
for f in "$REPO_ROOT"/scripts/*.sh "$REPO_ROOT"/scripts/menu/*.sh "$REPO_ROOT"/scripts/menu/*/*.sh; do
  sh -n "$f"
done

# 2. Verify restore_klipper_config_files and restore_moonraker_database do NOT delete data when archive is missing.
HELPER_SCRIPT_FOLDER="$REPO_ROOT"
. "$REPO_ROOT/scripts/paths.sh"
set_paths
. "$REPO_ROOT/scripts/menu/functions.sh"
. "$REPO_ROOT/scripts/backup_klipper_config.sh"
. "$REPO_ROOT/scripts/backup_moonraker_database.sh"
. "$REPO_ROOT/scripts/kamp.sh"
. "$REPO_ROOT/scripts/screws_tilt_adjust.sh"

PRINTER_DATA_FOLDER="$TMP_DIR/printer_data"
KLIPPER_CONFIG_FOLDER="$PRINTER_DATA_FOLDER/config"
HS_CONFIG_FOLDER="$KLIPPER_CONFIG_FOLDER/Helper-Script"
HS_BACKUP_FOLDER="$TMP_DIR/backup"
KLIPPER_EXTRAS_FOLDER="$TMP_DIR/extras"
PRINTER_CFG="$KLIPPER_CONFIG_FOLDER/printer.cfg"
MACROS_CFG="$KLIPPER_CONFIG_FOLDER/gcode_macro.cfg"
KAMP_FOLDER="$HS_CONFIG_FOLDER/KAMP"
VIRTUAL_PINS_FILE="$KLIPPER_EXTRAS_FOLDER/virtual_pins.py"
mkdir -p "$KLIPPER_CONFIG_FOLDER" "$PRINTER_DATA_FOLDER/database" "$KLIPPER_EXTRAS_FOLDER"
printf 'keep-config\n' > "$PRINTER_CFG"
printf 'keep-db\n' > "$PRINTER_DATA_FOLDER/database/data.mdb"

# On macOS host, wrap BSD sed so BusyBox/GNU-style `sed -i` works in this test harness.
if ! sed --version >/dev/null 2>&1; then
  sed() {
    if [ "${1:-}" = "-i" ]; then
      shift
      if command -v gsed >/dev/null 2>&1; then
        command gsed -i "$@"
      else
        python3 - "$@" <<'PY'
import re, sys
args = sys.argv[1:]
exprs = []
files = []
i = 0
while i < len(args):
    if args[i] == '-e':
        exprs.append(args[i + 1]); i += 2
    elif not exprs:
        exprs.append(args[i]); i += 1
    else:
        files.append(args[i]); i += 1
for path in files:
    lines = open(path).read().splitlines()
    for expr in exprs:
        m = re.match(r'^/(.+)/([ia])\s+(.+)$', expr)
        if m:
            pat, cmd, ins = m.groups()
            ins = ins.replace(r'\[', '[').replace(r'\]', ']').replace(r'\.', '.')
            out = []
            for line in lines:
                if re.search(pat, line):
                    if cmd == 'i':
                        out.append(ins); out.append(line)
                    else:
                        out.append(line); out.append(ins)
                else:
                    out.append(line)
            lines = out
            continue
        m = re.match(r'^/(.+)/d$', expr)
        if m:
            pat = m.group(1).replace(r'\/', '/')
            lines = [line for line in lines if not re.search(pat, line)]
    open(path, 'w').write('\n'.join(lines) + '\n')
PY
      fi
    else
      command sed "$@"
    fi
  }
fi

# Stub restart_klipper for isolated test execution.
restart_klipper() { :; }

HELPER_NONINTERACTIVE=1
export HELPER_NONINTERACTIVE

if restore_klipper_config_files >/dev/null 2>&1; then
  echo "FAIL: restore_klipper_config_files succeeded without an archive" >&2
  exit 1
fi
grep -q "keep-config" "$PRINTER_CFG"

if restore_moonraker_database >/dev/null 2>&1; then
  echo "FAIL: restore_moonraker_database succeeded without an archive" >&2
  exit 1
fi
grep -q "keep-db" "$PRINTER_DATA_FOLDER/database/data.mdb"

# 3. Verify backup + restore round-trip works cleanly in non-interactive mode.
backup_klipper_config_files >/dev/null
printf 'corrupted\n' > "$PRINTER_CFG"
restore_klipper_config_files >/dev/null
grep -q "keep-config" "$PRINTER_CFG"

backup_moonraker_database >/dev/null
printf 'corrupted\n' > "$PRINTER_DATA_FOLDER/database/data.mdb"
restore_moonraker_database >/dev/null
grep -q "keep-db" "$PRINTER_DATA_FOLDER/database/data.mdb"

# 4. Verify KAMP install/remove in non-interactive mode handles [virtual_pins] properly and never blocks on PrusaSlicer read.
cat > "$PRINTER_CFG" <<'EOF'
[include sensorless.cfg]
[include printer_params.cfg]
EOF
cat > "$MACROS_CFG" <<'EOF'
[gcode_macro START_PRINT]
gcode:
  CX_PRINT_DRAW_ONE_LINE
EOF
model="K2PLUS"
install_kamp >/dev/null
grep -q '^\[virtual_pins\]$' "$PRINTER_CFG"
grep -q 'include Helper-Script/KAMP/KAMP_Settings.cfg' "$PRINTER_CFG"
# Second install must not duplicate [virtual_pins].
install_kamp >/dev/null
[ "$(grep -c '^\[virtual_pins\]$' "$PRINTER_CFG")" -eq 1 ]
remove_kamp >/dev/null
! grep -q '^\[virtual_pins\]$' "$PRINTER_CFG"
! grep -q 'include Helper-Script/KAMP/KAMP_Settings.cfg' "$PRINTER_CFG"

# 5. Verify screws_tilt_adjust works on Python 3 systems without .pyc alongside .py and in non-interactive K1 mode.
printf '# mock\n' > "$KLIPPER_EXTRAS_FOLDER/screws_tilt_adjust.py"
model="K1"
install_screws_tilt_adjust >/dev/null
[ -L "$HS_CONFIG_FOLDER/screws-tilt-adjust.cfg" ]
remove_screws_tilt_adjust >/dev/null
[ -f "$KLIPPER_EXTRAS_FOLDER/screws_tilt_adjust.py" ]

echo "app_scripts_safety_test: OK"
