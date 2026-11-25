#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
HELPER_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

ok_msg() {
  echo "OK: $*"
}

error_msg() {
  echo "ERROR: $*" >&2
}

assert_equals() {
  expected="$1"
  actual="$2"
  message="$3"

  if [ "$expected" != "$actual" ]; then
    echo "FAIL: $message. Expected '$expected', got '$actual'." >&2
    exit 1
  fi
}

assert_contains() {
  needle="$1"
  file="$2"

  if ! grep -q "$needle" "$file"; then
    echo "FAIL: '$needle' was not found in $file." >&2
    exit 1
  fi
}

count_matches() {
  pattern="$1"
  file="$2"
  grep -c "$pattern" "$file"
}

. "$HELPER_ROOT/scripts/tools.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

sensorless_file="$tmp_dir/sensorless.cfg"
cat > "$sensorless_file" <<'CFG'
[gcode_macro _HOME_Y]
gcode:
  G28 Y

[homing_override]
axes: xyz
gcode:
  MOTOR_STALL_MODE DATA=1
  {% if home_all or 'Y' in params %}
    _HOME_Y
  {% endif %}
  MOTOR_SYS_PARAM NUM=1 DATA=1 ID=70 PARAMS=100 PARAMS_TYPE=float
  {% set acc = printer.toolhead.max_accel %}
  M204 S{acc}
CFG

if _patch_k2plus_homing_cfs_heartbeat "$sensorless_file"; then
  first_rc=0
else
  first_rc=$?
fi

assert_equals "0" "$first_rc" "first patch run should apply changes"
assert_contains "BOX_DISABLE_HEART_PROCESS TNN=T1A" "$sensorless_file"
assert_contains "G4 P500" "$sensorless_file"
assert_contains "M400" "$sensorless_file"
assert_contains "G4 P1000" "$sensorless_file"
assert_contains "BOX_ENABLE_HEART_PROCESS TNN=T1A" "$sensorless_file"
assert_equals "1" "$(count_matches 'BOX_DISABLE_HEART_PROCESS TNN=T1A' "$sensorless_file")" "disable heartbeat command count"
assert_equals "1" "$(count_matches 'BOX_ENABLE_HEART_PROCESS TNN=T1A' "$sensorless_file")" "enable heartbeat command count"
assert_equals "1" "$(count_matches 'G4 P1000' "$sensorless_file")" "Y homing settle command count"

if _patch_k2plus_homing_cfs_heartbeat "$sensorless_file"; then
  second_rc=0
else
  second_rc=$?
fi

assert_equals "2" "$second_rc" "second patch run should report already applied"
assert_equals "1" "$(count_matches 'BOX_DISABLE_HEART_PROCESS TNN=T1A' "$sensorless_file")" "disable heartbeat command should stay idempotent"
assert_equals "1" "$(count_matches 'BOX_ENABLE_HEART_PROCESS TNN=T1A' "$sensorless_file")" "enable heartbeat command should stay idempotent"
assert_equals "1" "$(count_matches 'G4 P1000' "$sensorless_file")" "Y homing settle command should stay idempotent"

echo "k2plus_homing_cfs_heartbeat_test: OK"
