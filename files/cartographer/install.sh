#!/bin/ash
set -e

SCRIPT_DIR=$(readlink -f $(dirname ${0}))

cd ${HOME}

export TMPDIR=/mnt/UDISK/tmp

HOMING_DIR=$(readlink -f ~/klipper/klippy/extras)
HOMING_FILE="${HOMING_DIR}/homing.py"
BED_MESH_FILE="${HOMING_DIR}/bed_mesh.py"
PRINTER_CFG="${HOME}/printer_data/config/printer.cfg"
CUSTOM_DIR="${HOME}/printer_data/config/custom"
CUSTOM_MAIN="${CUSTOM_DIR}/main.cfg"
CARTOGRAPHER_CFG="${CUSTOM_DIR}/cartographer.cfg"
PRTOUCH_CFG="${CUSTOM_DIR}/prtouch_v3.cfg"
BACKUP_DIR="/tmp/cartographer-backup-$(date +%s)"

backup_file() {
    local src="$1"
    local name="$2"
    if [ -f "$src" ]; then
        cp -f "$src" "${BACKUP_DIR}/${name}"
    else
        touch "${BACKUP_DIR}/${name}.missing"
    fi
}

restore_file() {
    local src="$1"
    local name="$2"
    if [ -f "${BACKUP_DIR}/${name}" ]; then
        cp -f "${BACKUP_DIR}/${name}" "$src"
    elif [ -f "${BACKUP_DIR}/${name}.missing" ]; then
        rm -f "$src"
    fi
}

rollback() {
    echo "E: install failed, rolling back changes"
    if [ -d "$BACKUP_DIR" ]; then
        restore_file "$HOMING_FILE" homing.py
        restore_file "$BED_MESH_FILE" bed_mesh.py
        restore_file "$PRINTER_CFG" printer.cfg
        restore_file "$CUSTOM_MAIN" main.cfg
        restore_file "$CARTOGRAPHER_CFG" cartographer.cfg
        restore_file "$PRTOUCH_CFG" prtouch_v3.cfg
    fi
}

SUCCESS=0
on_exit() {
    if [ "$SUCCESS" -eq 0 ]; then
        rollback
    fi
}
trap 'on_exit' EXIT

mkdir -p "$BACKUP_DIR"
backup_file "$HOMING_FILE" homing.py
backup_file "$BED_MESH_FILE" bed_mesh.py
backup_file "$PRINTER_CFG" printer.cfg
backup_file "$CUSTOM_MAIN" main.cfg
backup_file "$CARTOGRAPHER_CFG" cartographer.cfg
backup_file "$PRTOUCH_CFG" prtouch_v3.cfg

if [ ! -d cartographer-klipper/.git ]; then
    if [ -d cartographer-klipper ]; then
        rm -rf cartographer-klipper
    fi
    git clone https://github.com/jamincollins/cartographer-klipper.git
    git -C cartographer-klipper checkout k2
fi

if [ -L klippy-env ]; then
    echo "I: moving klippy-env to /mnt/UDISK/root"
    # move lippy-env to /mnt/UDISK
    rm -f klippy-env
    rsync -SHa /usr/share/klippy-env/ klippy-env/
fi

#TODO: how do we detect if we should upgrade?
upgrade_pip() {
    echo "I: upgrading klippy-env pip version"
    local pip_url="https://bootstrap.pypa.io/get-pip.py"
    local pip_file="${PWD}/get-pip.py"
    rm -f "$pip_file"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --retry 3 --retry-delay 2 -o "$pip_file" "$pip_url"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$pip_file" "$pip_url"
    else
        echo "E: curl or wget not found"
        return 1
    fi
    ~/klippy-env/bin/python3 "$pip_file"
    rm -f "$pip_file"
}
upgrade_pip

# ensure we are pulling wheels from piwheels
if ! grep -q 'extra-index-url=https://www.piwheels.org/simple' /etc/pip.conf; then
    echo 'extra-index-url=https://www.piwheels.org/simple' >> /etc/pip.conf
fi

# install requirements
echo "I: installing cartographer requirements"
~/klippy-env/bin/pip \
    install \
    --upgrade \
    --requirement cartographer-klipper/requirements.txt

# fix the klippy-env libraries
python3 ${SCRIPT_DIR}/fix_venv.py ~/klippy-env

# drop missing libraries in place
echo "I: installing cartographer libraries"
cp ${SCRIPT_DIR}/*.so* /usr/lib/

# install cartographer
echo "I: installing cartographer"
~/cartographer-klipper/install.sh

# install usb-serial bridge
mkdir -p /mnt/UDISK/bin
ln -sf  ${SCRIPT_DIR}/usb_bridge /mnt/UDISK/bin/usb_bridge
chmod +x /mnt/UDISK/bin/usb_bridge
ln -s ${SCRIPT_DIR}/cartographer.sh /mnt/UDISK/bin/cartographer.sh
ln -sf ${SCRIPT_DIR}/cartographer.init /etc/init.d/cartographer
ln -sf ${SCRIPT_DIR}/cartographer.init /opt/etc/init.d/S50cartographer
/etc/init.d/cartographer start

# install cartographer convenience scripts
ln -sf ${SCRIPT_DIR}/cartographer.sh /mnt/UDISK/bin
chmod +x /mnt/UDISK/bin/cartographer.sh

# remove the prtouch_v3 section from printer.cfg
python ${SCRIPT_DIR}/alter_config.py
# add a commented include to custom/main.cfg
python ${SCRIPT_DIR}/ensure_included.py \
    ~/printer_data/config/custom/main.cfg prtouch_v3.cfg True
# add the main.cfg to printer.cfg
python ${SCRIPT_DIR}/ensure_included.py \
    ~/printer_data/config/printer.cfg custom/main.cfg
# I believe I still want this as a true copy
# add the cartographer.cfg to main.cfg
cp ${SCRIPT_DIR}/cartographer.cfg ~/printer_data/config/custom
python ${SCRIPT_DIR}/ensure_included.py ~/printer_data/config/custom/main.cfg cartographer.cfg

# patch homing.py for scanner support
if grep -q "lookup_object('scanner')" "$HOMING_FILE"; then
    echo "I: homing.py already patched for scanner"
elif grep -q "self.prtouch_v3 = self.printer.lookup_object('prtouch_v3') if self.printer.objects.get('prtouch_v3') else None" "$HOMING_FILE"; then
    echo "I: applying homing scanner patch (conditional prtouch_v3)"
    patch -d "$HOMING_DIR" -p0 < "${SCRIPT_DIR}/homing.scanner.patch"
elif grep -q "self.prtouch_v3 = printer.lookup_object('prtouch_v3')" "$HOMING_FILE"; then
    echo "I: applying homing scanner patch (legacy)"
    patch -d "$HOMING_DIR" -p0 < "${SCRIPT_DIR}/homing.patch"
else
    echo "E: unsupported homing.py format, aborting"
    exit 1
fi
rm -f "${HOMING_FILE}c"

# replace the bed mesh
rm -f "${BED_MESH_FILE}" "${BED_MESH_FILE}c"
ln -sf "${SCRIPT_DIR}/bed_mesh.py" "${BED_MESH_FILE}"

# restart klipper
/etc/init.d/klipper restart

SUCCESS=1
