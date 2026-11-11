#!/bin/bash
# List PCIe devices whose link cannot sleep in ASPM L1, or does not right now.
# Read only: runs lspci and reads sysfs, never writes PCIe config.
#
# Usage: blockers.sh [lspci-vv-file]
#   no argument     run "lspci -vv" live, parent port from /sys/bus/pci/devices
#   file argument   parse a saved "lspci -vv" output instead (or set ASPM_BLOCKERS_INPUT);
#                   the parent port then comes from the bridges' "Bus: secondary=" lines
#
# Output: one tab separated line per listed device
#   group  bdf  name  lnkcap_aspm  lnkctl_aspm  parent_bdf  parent_lnkcap_aspm  parent_lnkctl_aspm
#   group A = the device does not offer L1, group B = it offers L1 but L1 is off.
#   Empty output = nothing found. Exit 1 = lspci could not be read.

INPUT="${1:-$ASPM_BLOCKERS_INPUT}"
PARENTS=$(mktemp) || exit 1
trap 'rm -f "$PARENTS"' EXIT

if [ -n "$INPUT" ]; then
	if [ ! -r "$INPUT" ]; then
		echo "cannot read $INPUT" >&2
		exit 1
	fi
	LSPCI=$(cat "$INPUT")
else
	LSPCI=$(lspci -vv 2>/dev/null) || { echo "lspci failed" >&2; exit 1; }
	# parent of each device = the directory above it in sysfs (pci0000:00 = none)
	for dev in /sys/bus/pci/devices/*; do
		[ -e "$dev" ] || continue
		parent=$(basename "$(dirname "$(readlink -f "$dev")")")
		echo "$(basename "$dev") $parent"
	done | sed 's/\b0000://g' > "$PARENTS"
fi

printf '%s\n' "$LSPCI" | awk -v parents="$PARENTS" '
function aspm_cap(line) {
	# "ASPM not supported" / "ASPM L0s" / "ASPM L1" / "ASPM L0s L1", ends at the comma
	if (!match(line, /ASPM [^,]*/)) return ""
	return substr(line, RSTART + 5, RLENGTH - 5)
}
function aspm_ctl(line,    s) {
	# "ASPM Disabled" / "ASPM L1 Enabled" / "ASPM L0s L1 Enabled", ends at the semicolon;
	# only this field counts, so old "Disabled-" and new "LnkDisable-" flags are never read
	if (!match(line, /ASPM [A-Za-z0-9 ]*/)) return ""
	s = substr(line, RSTART + 5, RLENGTH - 5)
	sub(/ +$/, "", s)
	return s
}
BEGIN {
	n = 0
	while ((getline l < parents) > 0) {
		split(l, f, " ")
		if (f[2] ~ /^[0-9a-f]+:[0-9a-f]+\.[0-7]$|^[0-9a-f]+:[0-9a-f]+:[0-9a-f]+\.[0-7]$/) sysparent[f[1]] = f[2]
		else sysparent[f[1]] = ""
	}
}
/^([0-9a-f]{4,}:)?[0-9a-f]{2}:[0-9a-f]{2}\.[0-7] / {
	n++
	bdf[n] = $1
	rest = substr($0, length($1) + 2)
	cls = rest; sub(/: .*/, "", cls)
	name = rest; sub(/^[^:]*: /, "", name)
	gsub(/ \((rev|prog-if) [^)]*\)/, "", name)
	gsub(/\t/, " ", name)
	nm[n] = name
	bridge[n] = (cls == "PCI bridge")
	cap[n] = ""; ctl[n] = ""
	idx[$1] = n
	next
}
n && /^[ \t]+LnkCap:/ { cap[n] = aspm_cap($0); next }
n && /^[ \t]+LnkCtl:/ { ctl[n] = aspm_ctl($0); next }
n && /^[ \t]+Bus: .*secondary=/ {
	if (match($0, /secondary=[0-9a-f]+/)) {
		sec = substr($0, RSTART + 10, RLENGTH - 10)
		dom = ""
		if (split(bdf[n], part, ":") == 3) dom = part[1] ":"
		busparent[dom sec] = bdf[n]
	}
	next
}
END {
	for (i = 1; i <= n; i++) {
		if (bridge[i] || cap[i] == "") continue
		if (cap[i] !~ /L1/) group = "A"
		else if (ctl[i] !~ /L1/) group = "B"
		else continue
		b = bdf[i]
		if (b in sysparent) p = sysparent[b]
		else {
			bus = b; sub(/:[0-9a-f]{2}\.[0-7]$/, "", bus)
			p = (bus in busparent) ? busparent[bus] : ""
		}
		pcap = ""; pctl = ""
		if (p != "" && (p in idx)) { pcap = cap[idx[p]]; pctl = ctl[idx[p]] }
		printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", group, b, nm[i], cap[i], ctl[i], p, pcap, pctl
	}
}'
