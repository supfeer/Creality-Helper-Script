#!/bin/ash
set -e

SCRIPT_DIR=$(readlink -f $(dirname ${0}))
ACTION=${1}
PATCH_LEGACY="${SCRIPT_DIR}/homing.patch"
PATCH_SCANNER="${SCRIPT_DIR}/homing.scanner.patch"
RESTORE_PATH="${SCRIPT_DIR}/restore-path.sh"
HOMING_FILE="${HOME}/klipper/klippy/extras/homing.py"

usage() {
    echo ""
    echo "${0} ACTION"
    echo ""
    echo "ACTION:"
    echo "  enable -- enables the cartographer probe, disabling the prtouch"
    echo "  disable -- disables the cartogrpher probe, enabling the prtouch"
    echo "  restart -- restarts the cartographer serial bridge"
    echo ""
}

case ${ACTION} in
    enable)
        ln -sf ~/cartographer-klipper/scanner.py ~/klipper/klippy/extras
        ln -sf ~/cartographer-klipper/cartographer.py ~/klipper/klippy/extras
        ln -sf ~/cartographer-klipper/idm.py ~/klipper/klippy/extras
        cd ~/klipper/klippy/extras
        if grep -q "lookup_object('scanner')" "${HOMING_FILE}"; then
            echo "I: homing.py already patched for scanner"
        elif grep -q "self.prtouch_v3 = self.printer.lookup_object('prtouch_v3') if self.printer.objects.get('prtouch_v3') else None" "${HOMING_FILE}"; then
            patch < "${PATCH_SCANNER}"
        else
            patch < "${PATCH_LEGACY}"
        fi
        rm -f homing.pyc
        rm -f bed_mesh.py*
        ln -sf "${SCRIPT_DIR}/bed_mesh.py" ./bed_mesh.py
        sed -E \
            -i \
            -e 's/(.*prtouch.*)/#\1/' \
            -e 's/#(.*carto.*)/\1/' \
            ~/printer_data/config/custom/main.cfg
        /etc/init.d/klipper restart
        ;;
    disable)
        rm -f ~/klipper/klippy/extras/scanner.py*
        rm -f ~/klipper/klippy/extras/cartographer.py*
        rm -f ~/klipper/klippy/extras/idm.py*
        sed -E \
            -i \
            -e 's/#(.*prtouch.*)/\1/' \
            -e 's/(.*carto.*)/#\1/' \
            ~/printer_data/config/custom/main.cfg
        sh "${RESTORE_PATH}" ~/klipper/klippy/extras/homing.py
        sh "${RESTORE_PATH}" ~/klipper/klippy/extras/homing.pyc
        sh "${RESTORE_PATH}" ~/klipper/klippy/extras/bed_mesh.py
        sh "${RESTORE_PATH}" ~/klipper/klippy/extras/bed_mesh.pyc
        /etc/init.d/klipper restart
        ;;
    restart)
        /etc/init.d/cartographer restart
        ;;
    *)
        usage
        ;;
esac
