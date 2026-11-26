#!/bin/sh
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
SERVER_PID=""
cleanup() {
  if [ -n "$SERVER_PID" ]; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

sh -n "$REPO_ROOT/scripts/k2_mainline_ota.sh"

# Start a local mock GitHub Releases server serving manifest.json, valid .img, and corrupted .img.
PORT_FILE="$TMP_DIR/port"
python3 - "$TMP_DIR" "$PORT_FILE" <<'PY' &
import hashlib, http.server, json, sys
from pathlib import Path

root = Path(sys.argv[1])
port_file = Path(sys.argv[2])

good_payload = b"K2_HELPER_OTA_VALID_PAYLOAD_" * 1024
good_sha = hashlib.sha256(good_payload).hexdigest()
bad_payload = bytearray(good_payload)
bad_payload[42] ^= 0xFF
filename = "CR0CN240110C10_ota_img_V1.1.4.952.img"

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass
    def do_GET(self):
        if self.path == "/manifest-good.json":
            body = json.dumps({
                "schema_version": 1,
                "version": "1.1.4.952",
                "board": "CR0CN240110C10",
                "model": "F008",
                "filename": filename,
                "size": len(good_payload),
                "sha256": good_sha,
                "download_url": f"http://127.0.0.1:{self.server.server_port}/good.img",
            }).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif self.path == "/manifest-bad.json":
            body = json.dumps({
                "schema_version": 1,
                "version": "1.1.4.952",
                "board": "CR0CN240110C10",
                "model": "F008",
                "filename": filename,
                "size": len(good_payload),
                "sha256": good_sha,
                "download_url": f"http://127.0.0.1:{self.server.server_port}/bad.img",
            }).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif self.path == "/good.img":
            self.send_response(200)
            self.send_header("Content-Length", str(len(good_payload)))
            self.end_headers()
            self.wfile.write(good_payload)
        elif self.path == "/bad.img":
            self.send_response(200)
            self.send_header("Content-Length", str(len(bad_payload)))
            self.end_headers()
            self.wfile.write(bytes(bad_payload))
        else:
            self.send_response(404)
            self.end_headers()

srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
port_file.write_text(str(srv.server_port), encoding="utf-8")
srv.serve_forever()
PY
SERVER_PID=$!

i=0
while [ ! -s "$PORT_FILE" ] && [ "$i" -lt 50 ]; do
  sleep 0.1
  i=$((i + 1))
done
PORT="$(cat "$PORT_FILE")"

. "$REPO_ROOT/scripts/k2_mainline_ota.sh"

HELPER_NONINTERACTIVE=1
K2_OTA_ALLOW_HTTP=1
K2_OTA_NO_REBOOT=1
K2_OTA_MIN_EXTRA_BYTES=0
K2_OTA_CURRENT_VERSION="1.1.4.11"
K2_MAINLINE_UPGRADE_DIR="$TMP_DIR/upgrade"
INSTALL_LOG="$TMP_DIR/install.log"
MOCK_OTA="$TMP_DIR/mock_local_ota_update.sh"
cat > "$MOCK_OTA" <<EOF
#!/bin/sh
echo "INSTALLED:\$1" >> "$INSTALL_LOG"
echo "ota update ok"
exit 0
EOF
chmod +x "$MOCK_OTA"
MOCK_OTA_SILENT_FAIL="$TMP_DIR/mock_local_ota_silent_fail.sh"
cat > "$MOCK_OTA_SILENT_FAIL" <<EOF
#!/bin/sh
echo "#### update failed 1"
exit 0
EOF
chmod +x "$MOCK_OTA_SILENT_FAIL"
K2_MAINLINE_LOCAL_OTA_BIN="$MOCK_OTA"
export HELPER_NONINTERACTIVE K2_OTA_ALLOW_HTTP K2_OTA_NO_REBOOT K2_OTA_MIN_EXTRA_BYTES K2_OTA_CURRENT_VERSION

# 1. Check detects update from 1.1.4.11 -> 1.1.4.952.
K2_MAINLINE_MANIFEST_URL="http://127.0.0.1:${PORT}/manifest-good.json"
out="$(check_k2_mainline_ota)"
printf '%s\n' "$out" | grep -q "Update available: yes"

# 2. Corrupted image must be rejected before calling local_ota_update.sh and leave no file behind.
K2_MAINLINE_MANIFEST_URL="http://127.0.0.1:${PORT}/manifest-bad.json"
if install_k2_mainline_ota >/dev/null 2>&1; then
  echo "FAIL: corrupted image passed SHA-256 verification" >&2
  exit 1
fi
[ ! -f "$INSTALL_LOG" ]
[ ! -f "$K2_MAINLINE_UPGRADE_DIR/CR0CN240110C10_ota_img_V1.1.4.952.img" ]

# 3. Valid image passes SHA-256 and invokes local_ota_update.sh.
K2_MAINLINE_MANIFEST_URL="http://127.0.0.1:${PORT}/manifest-good.json"
install_k2_mainline_ota >/dev/null
grep -q "INSTALLED:$K2_MAINLINE_UPGRADE_DIR/CR0CN240110C10_ota_img_V1.1.4.952.img" "$INSTALL_LOG"

# 4. Installer exiting 0 without 'ota update ok' (stock swupdate_cmd.sh behavior on failure) must fail.
K2_MAINLINE_LOCAL_OTA_BIN="$MOCK_OTA_SILENT_FAIL"
if install_k2_mainline_ota >/dev/null 2>&1; then
  echo "FAIL: silent swupdate_cmd.sh failure was treated as success" >&2
  exit 1
fi

echo "k2_mainline_ota_test: OK"
