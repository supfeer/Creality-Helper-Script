#!/bin/sh

set -e

function _cartographer_require_k2plus() {
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
  echo "Error: Cartographer flashing is supported only on K2PLUS (F008)."
  return 1
}

function _cartographer_python_bin() {
  local python_bin="/mnt/UDISK/root/klippy-env/bin/python"
  if [ ! -x "$python_bin" ]; then
    python_bin="$(command -v python3 2>/dev/null || command -v python 2>/dev/null || true)"
  fi
  if [ -z "$python_bin" ]; then
    echo "Error: Python not found."
    return 1
  fi
  echo "$python_bin"
}

function _cartographer_check_libusb() {
  if [ ! -f /usr/lib/libusb-1.0.so.0 ]; then
    echo "Error: libusb not found at /usr/lib/libusb-1.0.so.0."
    return 1
  fi
}

function _cartographer_install_pyusb() {
  local python_bin="$1"
  "$python_bin" - <<'PY'
import importlib.util
import subprocess
import sys

if importlib.util.find_spec("usb") is None:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyusb"])
else:
    print("pyusb already installed")
PY
}

function _cartographer_fetch_tools() {
  local python_bin="$1"
  "$python_bin" - <<'PY'
import os
import urllib.request

def fetch(url, path):
    if os.path.exists(path) and os.path.getsize(path) > 0:
        print(f"Using existing {path}")
        return
    print(f"Downloading {url}")
    urllib.request.urlretrieve(url, path)

fetch(
    "https://raw.githubusercontent.com/Klipper3d/klipper/master/lib/canboot/flash_can.py",
    "/tmp/flash_can.py",
)
fetch(
    "https://raw.githubusercontent.com/Cartographer3D/cartographer-klipper/master/firmware/v2-v3/survey/5.1.0/Survey_Cartographer_K1_USB_8kib_offset.bin",
    "/tmp/Survey_Cartographer_K1_USB_8kib_offset.bin",
)
PY
}

function install_cartographer_k2plus_prereqs() {
  _cartographer_require_k2plus
  local python_bin
  python_bin="$(_cartographer_python_bin)"
  _cartographer_check_libusb

  echo "Installing Python prerequisites..."
  _cartographer_install_pyusb "$python_bin"

  echo "Downloading flash tools and firmware..."
  _cartographer_fetch_tools "$python_bin"

  echo "Cartographer flash prerequisites installed."
}

function flash_cartographer_k2plus() {
  _cartographer_require_k2plus

  if ! command -v lsusb >/dev/null 2>&1; then
    echo "Error: lsusb not available."
    return 1
  fi

  if ! lsusb | grep -q "1d50:614e"; then
    echo "Error: Cartographer not detected (VID:PID 1d50:614e)."
    return 1
  fi

  local python_bin
  python_bin="$(_cartographer_python_bin)"
  _cartographer_check_libusb

  echo "Checking prerequisites..."
  _cartographer_install_pyusb "$python_bin"
  _cartographer_fetch_tools "$python_bin"

  echo "Entering bootloader..."
  "$python_bin" - <<'PY'
import struct
import usb.core
import usb.util
import usb.backend.libusb1

backend = usb.backend.libusb1.get_backend(
    find_library=lambda x: "/usr/lib/libusb-1.0.so.0"
)
if backend is None:
    raise SystemExit("No libusb backend found")

dev = usb.core.find(idVendor=0x1D50, idProduct=0x614E, backend=backend)
if dev is None:
    raise SystemExit("Cartographer device not found")

try:
    dev.set_configuration()
except usb.core.USBError:
    pass

cfg = dev.get_active_configuration()
intf = cfg[(0, 0)]
iface = intf.bInterfaceNumber
try:
    if dev.is_kernel_driver_active(iface):
        dev.detach_kernel_driver(iface)
except Exception:
    pass
usb.util.claim_interface(dev, iface)
line_coding = struct.pack("<I", 1200) + bytes([0, 0, 8])
dev.ctrl_transfer(0x21, 0x20, 0, iface, line_coding)
dev.ctrl_transfer(0x21, 0x22, 0, iface, None)
usb.util.release_interface(dev, iface)
usb.util.dispose_resources(dev)
PY

  echo "Waiting for Katapult bootloader..."
  local i=1
  while [ $i -le 30 ]; do
    if lsusb | grep -q "1d50:6177"; then
      break
    fi
    sleep 1
    i=$((i + 1))
  done
  if ! lsusb | grep -q "1d50:6177"; then
    echo "Error: Katapult bootloader not detected."
    return 1
  fi

  cat > /tmp/katapult_bridge.py <<'PY'
#!/usr/bin/env python3
import os
import pty
import time
import threading
import usb.core
import usb.util
import usb.backend.libusb1
import fcntl

VID = 0x1D50
PID = 0x6177
LINK_PATH = "/tmp/katapult_tty"
LIBUSB_PATH = "/usr/lib/libusb-1.0.so.0"

backend = usb.backend.libusb1.get_backend(find_library=lambda x: LIBUSB_PATH)
if backend is None:
    raise SystemExit("No libusb backend found")

dev = usb.core.find(idVendor=VID, idProduct=PID, backend=backend)
if dev is None:
    raise SystemExit("Katapult device not found")

try:
    dev.set_configuration()
except usb.core.USBError:
    pass

cfg = dev.get_active_configuration()
intf = None
ep_in = None
ep_out = None
for i in cfg:
    for ep in i:
        if usb.util.endpoint_type(ep.bmAttributes) != usb.util.ENDPOINT_TYPE_BULK:
            continue
        if usb.util.endpoint_direction(ep.bEndpointAddress) == usb.util.ENDPOINT_IN:
            ep_in = ep
        else:
            ep_out = ep
    if ep_in is not None and ep_out is not None:
        intf = i
        break

if intf is None or ep_in is None or ep_out is None:
    raise SystemExit("Could not find bulk IN/OUT endpoints")

iface = intf.bInterfaceNumber
try:
    if dev.is_kernel_driver_active(iface):
        dev.detach_kernel_driver(iface)
except Exception:
    pass
usb.util.claim_interface(dev, iface)

master, slave = pty.openpty()
slave_name = os.ttyname(slave)
if os.path.exists(LINK_PATH) or os.path.islink(LINK_PATH):
    os.unlink(LINK_PATH)
os.symlink(slave_name, LINK_PATH)

flags = fcntl.fcntl(master, fcntl.F_GETFL)
fcntl.fcntl(master, fcntl.F_SETFL, flags | os.O_NONBLOCK)

print("BRIDGE_READY", LINK_PATH, "->", slave_name, flush=True)

running = True

def usb_to_pty():
    while running:
        try:
            data = dev.read(ep_in.bEndpointAddress, ep_in.wMaxPacketSize, timeout=100)
            if data:
                os.write(master, data.tobytes())
        except usb.core.USBError as e:
            if getattr(e, "errno", None) == 110:
                continue
            break
        except OSError:
            break

def pty_to_usb():
    while running:
        try:
            data = os.read(master, 4096)
            if data:
                dev.write(ep_out.bEndpointAddress, data, timeout=100)
        except BlockingIOError:
            time.sleep(0.01)
        except usb.core.USBError as e:
            if getattr(e, "errno", None) == 110:
                continue
            break
        except OSError:
            break

t1 = threading.Thread(target=usb_to_pty, daemon=True)
t2 = threading.Thread(target=pty_to_usb, daemon=True)
t1.start()
t2.start()

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    running = False
PY

  "$python_bin" /tmp/katapult_bridge.py >/tmp/katapult_bridge.log 2>&1 &
  local bridge_pid=$!

  i=1
  while [ $i -le 10 ]; do
    if [ -e /tmp/katapult_tty ]; then
      break
    fi
    sleep 1
    i=$((i + 1))
  done
  if [ ! -e /tmp/katapult_tty ]; then
    echo "Error: Katapult bridge did not start."
    cat /tmp/katapult_bridge.log || true
    kill "$bridge_pid" || true
    return 1
  fi

  echo "Flashing firmware..."
  "$python_bin" /tmp/flash_can.py -d /tmp/katapult_tty -f /tmp/Survey_Cartographer_K1_USB_8kib_offset.bin

  kill "$bridge_pid" || true
  rm -f /tmp/katapult_bridge.py /tmp/katapult_bridge.log /tmp/katapult_tty

  echo "Cartographer firmware flash completed."
}

function install_cartographer_k2plus() {
  _cartographer_require_k2plus
  export PATH="/opt/bin:/opt/sbin:$PATH"

  local install_script_primary="/mnt/UDISK/root/k2-improvements/features/cartographer/install.sh"
  local install_script_fallback="${HELPER_SCRIPT_FOLDER}/k2-improvements-main/features/cartographer/install.sh"
  local install_script="$install_script_primary"

  if [ ! -f "$install_script" ]; then
    install_script="$install_script_fallback"
  fi

  if [ ! -f "$install_script" ]; then
    echo "Cartographer install script not found: $install_script_primary or $install_script_fallback"
    return 1
  fi

  sh "$install_script"
}
