#!/usr/bin/bash

. /bin/configure-ironic.sh

# Ramdisk logs
mkdir -p /shared/log/ironic/deploy

cp -f /tmp/uefi_esp.img /shared/html/uefi_esp.img

# It's possible for the dbsync to fail if mariadb is not up yet, so
# retry until success
until ironic-dbsync --config-file /etc/ironic/ironic.conf version; do
    echo "WARNING: ironic-dbsync failed, retrying"
    sleep 1
done

# Try creating the complete schema, it's much faster than upgrading.
if ! ironic-dbsync --config-file /etc/ironic/ironic.conf create_schema; then
    echo "Creating schema failed, falling back to schema upgrade"
    ironic-dbsync --config-file /etc/ironic/ironic.conf upgrade || {
        echo "ERROR: failed to create DB schema, cannot start the conductor";
        exit 1;
    }
fi

exec /usr/bin/ironic-conductor --config-file /etc/ironic/ironic.conf
