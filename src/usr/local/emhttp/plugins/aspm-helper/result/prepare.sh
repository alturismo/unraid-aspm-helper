#!/bin/bash

touch /usr/local/emhttp/plugins/aspm-helper/result/lspci-t_result.txt
touch /usr/local/emhttp/plugins/aspm-helper/result/aspm_result.txt

lspci -vv | awk '/ASPM/{print $0}' RS= | grep -P '(^[a-z0-9:.]+|ASPM |Disabled;|Enabled;)' > /usr/local/emhttp/plugins/aspm-helper/result/lspci.txt

cat lspci.txt | grep .*:.*:.* | cut -f1 -d' ' | grep '[0-9]\{1\}' > /usr/local/emhttp/plugins/aspm-helper/result/testdevices.txt
cat lspci.txt | grep -ohn "[[:alpha:]]*abled[[:alpha:]]*" | awk -i inplace '!seen[$0]++' > /usr/local/emhttp/plugins/aspm-helper/result/teststate.txt
paste -d\; testdevices.txt teststate.txt | grep -i "Disabled" > /usr/local/emhttp/plugins/aspm-helper/result/lspci_result.txt
rm /usr/local/emhttp/plugins/aspm-helper/result/testdevices.txt
rm /usr/local/emhttp/plugins/aspm-helper/result/teststate.txt

lspci -t > /usr/local/emhttp/plugins/aspm-helper/result/lspci-t.txt

rm /usr/local/emhttp/plugins/aspm-helper/result/lspci-t_result.txt

IFS=$'\n'       # make newlines the only separator
set -f          # disable globbing
for i in $(cat < "lspci-t.txt"); do
	checkup2=$(echo $i | cut -c 59-62)
	checkupdot=$(echo $i | cut -c 61)
	if [[ $checkupdot =~ "." ]]; then
		device2="$checkup2"
		checkup1=$(echo $i | cut -c 52-53)
	if [[ $checkup1 =~ ^[[:digit:]] ]]; then
		device1="$checkup1"
	fi
	device="$device1:$device2"
	checkup3=$(echo $i | cut -c 14-17)
	if [[ $checkup3 =~ ^[[:digit:]] ]]; then
		root2="$checkup3"
	fi
	echo "$device 00:$root2" >> /usr/local/emhttp/plugins/aspm-helper/result/lspci-t_result.txt
	fi
done

for i in $(cat < "lspci-t.txt"); do
	checkup2=$(echo $i | cut -c 46-49)
	checkupdot=$(echo $i | cut -c 48)
	if [[ $checkupdot =~ "." ]]; then
		device2="$checkup2"
		checkup1=$(echo $i | cut -c 36-37)
	if [[ $checkup1 =~ ^[[:digit:]] ]]; then
		device1="$checkup1"
	fi
	device="$device1:$device2"
	checkup3=$(echo $i | cut -c 14-17)
	if [[ $checkup3 =~ ^[[:digit:]] ]]; then
		root2="$checkup3"
	fi
	echo "$device 00:$root2" >> /usr/local/emhttp/plugins/aspm-helper/result/lspci-t_result.txt
	fi
done

for i in $(cat < "lspci-t.txt"); do
	checkup2=$(echo $i | cut -c 27-30)
	checkupdot=$(echo $i | cut -c 29)
	if [[ $checkupdot =~ "." ]]; then
		device2="$checkup2"
		checkup1=$(echo $i | cut -c 20-21)
	if [[ $checkup1 =~ ^[[:digit:]] ]]; then
		device1="$checkup1"
	fi
	device="$device1:$device2"
	checkup3=$(echo $i | cut -c 14-17)
	if [[ $checkup3 =~ ^[[:digit:]] ]]; then
		root2="$checkup3"
	fi
	echo "$device 00:$root2" >> /usr/local/emhttp/plugins/aspm-helper/result/lspci-t_result.txt
	fi
done

for i in $(cat < "lspci-t.txt"); do
	checkup2=$(echo $i | cut -c 30-33)
	checkupdot=$(echo $i | cut -c 32)
	if [[ $checkupdot =~ "." ]]; then
		device2="$checkup2"
		checkup1=$(echo $i | cut -c 20-21)
	if [[ $checkup1 =~ ^[[:digit:]] ]]; then
		device1="$checkup1"
	fi
	device="$device1:$device2"
	checkup3=$(echo $i | cut -c 14-17)
	if [[ $checkup3 =~ ^[[:digit:]] ]]; then
		root2="$checkup3"
	fi
	echo "$device 00:$root2" >> /usr/local/emhttp/plugins/aspm-helper/result/lspci-t_result.txt
	fi
done

IFS=$'\n'       # make newlines the only separator
set -f          # disable globbing

rm /usr/local/emhttp/plugins/aspm-helper/result/aspm_result.txt

for i in $(cat < "lspci_result.txt"); do
	disabled_device=$(echo $i | cut -c 1-7)
	for j in $(cat < "lspci-t_result.txt"); do
		devicepath=$(echo $j | cut -c 1-7)
		if [[ "$disabled_device" == "$devicepath" ]]; then
			echo "$j" >> /usr/local/emhttp/plugins/aspm-helper/result/aspm_result.txt
		fi
	done	
done

touch /usr/local/emhttp/plugins/aspm-helper/result/aspm_result.txt

exit;