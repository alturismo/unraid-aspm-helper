#!/bin/bash

cat /var/log/syslog | grep -i "aspm-helper:" | grep -v "pcilib" > /usr/local/emhttp/plugins/aspm-helper/aspm_log.txt

exit;
