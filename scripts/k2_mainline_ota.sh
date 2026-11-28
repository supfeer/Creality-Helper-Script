#!/bin/sh

set -e

K2_MAINLINE_OTA_REPO="${K2_MAINLINE_OTA_REPO:-supfeer/k2-mainline}"
K2_MAINLINE_MANIFEST_URL="${K2_MAINLINE_MANIFEST_URL:-https://github.com/${K2_MAINLINE_OTA_REPO}/releases/latest/download/manifest.json}"
K2_MAINLINE_UPGRADE_DIR="${K2_MAINLINE_UPGRADE_DIR:-/mnt/UDISK/creality/upgrade}"
K2_MAINLINE_LOCAL_OTA_BIN="${K2_MAINLINE_LOCAL_OTA_BIN:-/etc/ota_bin/local_ota_update.sh}"

_k2_ota_python() {
  if [ -n "${K2_OTA_PYTHON:-}" ] && [ -x "$K2_OTA_PYTHON" ]; then
    printf '%s\n' "$K2_OTA_PYTHON"
    return 0
  fi
  if [ -x /usr/share/klippy-env/bin/python ]; then
    printf '%s\n' "/usr/share/klippy-env/bin/python"
    return 0
  fi
  if command -v python3 >/dev/null 2>&1; then
    command -v python3
    return 0
  fi
  return 1
}

check_k2_mainline_ota() {
  local py_bin
  py_bin="$(_k2_ota_python)" || {
    echo "Error: Python 3 is required to check K2 Mainline OTA releases." >&2
    return 1
  }
  "$py_bin" -B - "$K2_MAINLINE_MANIFEST_URL" <<'PY'
import json, os, re, ssl, subprocess, sys, urllib.parse, urllib.request
from pathlib import Path

manifest_url = sys.argv[1]
allow_http = os.environ.get("K2_OTA_ALLOW_HTTP", "") == "1"
parsed = urllib.parse.urlparse(manifest_url)
if parsed.scheme != "https" and not (allow_http and parsed.scheme == "http" and parsed.hostname in ("127.0.0.1", "localhost")):
    raise SystemExit(f"Refusing insecure manifest URL: {manifest_url}")

ctx = ssl.create_default_context() if parsed.scheme == "https" else None
if ctx is not None:
    for ca in (os.environ.get("SSL_CERT_FILE", ""), "/etc/ssl/certs/ca-certificates.crt", "/etc/ssl/cert.pem"):
        if ca and Path(ca).is_file():
            ctx.load_verify_locations(cafile=ca)
            break

req = urllib.request.Request(manifest_url, headers={"User-Agent": "creality-helper-k2-ota/1.0"})
with urllib.request.urlopen(req, timeout=15.0, context=ctx) as resp:
    manifest = json.loads(resp.read(256 * 1024).decode("utf-8"))

if manifest.get("schema_version") != 1 or manifest.get("board") != "CR0CN240110C10" or manifest.get("model") != "F008":
    raise SystemExit("Invalid K2 Mainline OTA manifest")

cur = os.environ.get("K2_OTA_CURRENT_VERSION", "").strip()
if not cur:
    try:
        cur = subprocess.check_output(["fw_printenv", "-n", "version"], text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        cur = "unknown"

def vtuple(s):
    return tuple(int(x) for x in re.findall(r"[0-9]+", s or ""))

latest = str(manifest["version"])
avail = vtuple(latest) > vtuple(cur) if cur != "unknown" else True
print(f"Current version : {cur}")
print(f"Latest release  : {latest} ({manifest['filename']})")
print(f"Update available: {'yes' if avail else 'no'}")
PY
}

install_k2_mainline_ota() {
  local force_flag="${K2_OTA_FORCE:-0}"
  local no_reboot="${K2_OTA_NO_REBOOT:-0}"
  local py_bin

  if [ "${HELPER_NONINTERACTIVE:-0}" != "1" ]; then
    local yn
    while true; do
      echo ""
      printf "Download and install the latest K2 Mainline firmware from %s? [y/n]: " "$K2_MAINLINE_OTA_REPO"
      read -r yn
      case "$yn" in
        Y|y) break ;;
        N|n) return 0 ;;
        *) echo "Please answer y or n." ;;
      esac
    done
  fi

  py_bin="$(_k2_ota_python)" || {
    echo "Error: Python 3 is required to install K2 Mainline OTA releases." >&2
    return 1
  }

  local img_path
  if ! img_path="$("$py_bin" -B - "$K2_MAINLINE_MANIFEST_URL" "$K2_MAINLINE_UPGRADE_DIR" "$force_flag" <<'PY'
import hashlib, json, os, re, socket, ssl, subprocess, sys, urllib.parse, urllib.request
from pathlib import Path

manifest_url, upgrade_dir_s, force_s = sys.argv[1], sys.argv[2], sys.argv[3]
allow_http = os.environ.get("K2_OTA_ALLOW_HTTP", "") == "1"

def check_url(u):
    p = urllib.parse.urlparse(u)
    if p.scheme == "https" and p.netloc:
        return u
    if allow_http and p.scheme == "http" and p.hostname in ("127.0.0.1", "localhost"):
        return u
    raise SystemExit(f"Refusing insecure URL: {u}")

def ssl_ctx(u):
    if not u.startswith("https://"):
        return None
    ctx = ssl.create_default_context()
    for ca in (os.environ.get("SSL_CERT_FILE", ""), "/etc/ssl/certs/ca-certificates.crt", "/etc/ssl/cert.pem"):
        if ca and Path(ca).is_file():
            ctx.load_verify_locations(cafile=ca)
            break
    return ctx

# Refuse installation if Klipper is actively printing.
uds = Path(os.environ.get("K2_OTA_KLIPPY_UDS", "/tmp/klippy_uds"))
if uds.is_socket():
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.settimeout(2.0)
    try:
        s.connect(str(uds))
        s.sendall(json.dumps({"id": 9103, "method": "objects/query", "params": {"objects": {"print_stats": None, "idle_timeout": None}}}).encode() + b"\x03")
        buf = bytearray()
        while True:
            ch = s.recv(4096)
            if not ch:
                break
            buf.extend(ch)
            if 3 in ch:
                break
        if buf:
            st = json.loads(buf.split(b"\x03", 1)[0].decode("utf-8", "replace")).get("result", {}).get("status", {})
            if st.get("print_stats", {}).get("state") == "printing" or st.get("idle_timeout", {}).get("state") == "Printing":
                raise SystemExit("Refusing OTA while printer is actively printing.")
    except OSError:
        pass
    finally:
        s.close()

m_url = check_url(manifest_url)
req = urllib.request.Request(m_url, headers={"User-Agent": "creality-helper-k2-ota/1.0"})
with urllib.request.urlopen(req, timeout=15.0, context=ssl_ctx(m_url)) as resp:
    manifest = json.loads(resp.read(256 * 1024).decode("utf-8"))

if manifest.get("schema_version") != 1 or manifest.get("board") != "CR0CN240110C10" or manifest.get("model") != "F008":
    raise SystemExit("Invalid K2 Mainline OTA manifest")

version = str(manifest["version"])
filename = str(manifest["filename"])
if not re.match(r"^CR0CN240110C10_ota_img_V\d+\.\d+\.\d+\.\d+\.img$", filename):
    raise SystemExit(f"Unsafe manifest filename: {filename}")

expected_size = int(manifest["size"])
expected_sha = str(manifest["sha256"]).lower()
if not re.match(r"^[0-9a-f]{64}$", expected_sha) or expected_size <= 0:
    raise SystemExit("Invalid manifest size or sha256")

cur = os.environ.get("K2_OTA_CURRENT_VERSION", "").strip()
if not cur:
    try:
        cur = subprocess.check_output(["fw_printenv", "-n", "version"], text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        cur = ""

def vtuple(s):
    return tuple(int(x) for x in re.findall(r"[0-9]+", s or ""))

if force_s != "1" and cur and vtuple(version) <= vtuple(cur):
    sys.stderr.write(f"Already up to date (current={cur}, latest={version}).\n")
    print("UP_TO_DATE")
    raise SystemExit(0)

dl_url = check_url(str(manifest["download_url"]))
upgrade_dir = Path(upgrade_dir_s)
upgrade_dir.mkdir(parents=True, exist_ok=True)
final_path = upgrade_dir / filename
tmp_path = upgrade_dir / f".{filename}.{os.getpid()}.part"

st = os.statvfs(str(upgrade_dir))
free_bytes = st.f_bavail * st.f_frsize
min_extra = int(os.environ.get("K2_OTA_MIN_EXTRA_BYTES", str(512 * 1024 * 1024)))
if free_bytes < expected_size + min_extra:
    raise SystemExit(f"Insufficient free space in {upgrade_dir}: {free_bytes} bytes")

sha = hashlib.sha256()
total = 0
try:
    dl_req = urllib.request.Request(dl_url, headers={"User-Agent": "creality-helper-k2-ota/1.0"})
    with urllib.request.urlopen(dl_req, timeout=30.0, context=ssl_ctx(dl_url)) as resp, tmp_path.open("wb") as out:
        while True:
            chunk = resp.read(65536)
            if not chunk:
                break
            total += len(chunk)
            if total > expected_size:
                raise SystemExit(f"Downloaded size exceeded manifest ({total} > {expected_size})")
            out.write(chunk)
            sha.update(chunk)
        out.flush()
        os.fsync(out.fileno())
    if total != expected_size:
        raise SystemExit(f"Downloaded size mismatch: {total} != {expected_size}")
    if sha.hexdigest() != expected_sha:
        raise SystemExit(f"SHA-256 mismatch: {sha.hexdigest()} != {expected_sha}")
    os.replace(tmp_path, final_path)
except BaseException:
    tmp_path.unlink(missing_ok=True)
    raise

print(str(final_path))
PY
)"; then
    return 1
  fi

  if [ -z "$img_path" ] || [ "$img_path" = "UP_TO_DATE" ]; then
    [ "$img_path" = "UP_TO_DATE" ] && return 0
    return 1
  fi

  if [ ! -f "$K2_MAINLINE_LOCAL_OTA_BIN" ]; then
    echo "Error: Missing OTA installer script: $K2_MAINLINE_LOCAL_OTA_BIN" >&2
    return 1
  fi

  echo "Installing verified K2 Mainline OTA image: $img_path"
  local ota_out
  if ! ota_out="$(sh "$K2_MAINLINE_LOCAL_OTA_BIN" "$img_path" 2>&1)"; then
    printf '%s\n' "$ota_out" >&2
    return 1
  fi
  printf '%s\n' "$ota_out"
  if ! printf '%s\n' "$ota_out" | grep -q "ota update ok"; then
    echo "Error: SWUpdate did not confirm 'ota update ok'." >&2
    if [ -f /mnt/UDISK/swupdate.log ]; then
      tail -n 20 /mnt/UDISK/swupdate.log >&2 || true
    fi
    return 1
  fi
  echo "K2 Mainline OTA installation finished."

  if [ "$no_reboot" != "1" ]; then
    sync
    if [ "${HELPER_NONINTERACTIVE:-0}" = "1" ]; then
      echo "Rebooting printer in 2 seconds..."
      (sleep 2; reboot) >/dev/null 2>&1 </dev/null &
    else
      reboot
    fi
  fi
}
