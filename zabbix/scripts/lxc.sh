#!/bin/sh

ZABBIX_SENDER='/usr/bin/env zabbix_sender'
ZABBIX_CONFIG='/etc/zabbix/zabbix_agentd.conf'
ZABBIX_SENDER_DEBUG=0

#
# Add visudo rule by command:
#visudo -f /etc/sudoers.d/zabbix
# Add rule line:
#zabbix ALL=NOPASSWD:/bin/sh /etc/zabbix/scripts/lxc.sh *
#
# WARNING: Correctly setup 'Hostname=' in config is REQUIRED!
# REQUIRED binaries: lxc-ls, lxc-info, lxc-attach, sed, awk, zabbix_sender.


discover() {
	lxc-ls | awk -v hostname=$(hostname) '
		BEGIN{out="{\"data\":[";f=""}
		{
			cmd="lxc-info -s -n"$1
			if (f == "") {
				out=out"{"
				f=","
			} else {
				out=out",{"
			}
			while ((cmd | getline c) > 0) {
				split(c, a, " ")
				out=out"\"{#CTID}\":\""$0"\","
				out=out"\"{#CTSTATUS}\":\""a[2]"\","
				out=out"\"{#VENAME}\":\""hostname"\""
			}
			out=out"}"
		}
		END {print out"]}"}'
}


lxc_info() {
	lxc-info -Hn$CTID | awk -F: -v ct=$1 '{
			gsub("^ ", "", $2)
			if($1 ~ "IP") print ct, "lxc.info.ip", $2
			if($1 ~ "State") print ct, "lxc.info.status", $2
			if($1 ~ "RX bytes") print ct, "lxc.info.net.in", $2
			if($1 ~ "TX bytes") print ct, "lxc.info.net.out", $2
			if($1 ~ "Memory use") print ct, "lxc.info.usedmem", $2
			if($1 ~ "CPU use") print ct, "lxc.info.cpu", $2/1000000000
		}'
}


lxc_cgroup() {
	for i in memory.limit_in_bytes \
		memory.max_usage_in_bytes \
		memory.failcnt \
		cpuacct.stat;
	do
		cgdata=$(lxc-cgroup -n $1 $i 2>/dev/null || exit 1)
		if [ -n "$cgdata" ]; then
			case $i in
				'cpuacct.stat')
					echo $cgdata | awk -v ct=$1 '
						/system/{print ct, "lxc.cgroup.cpuacct.stat.system", $2/100}
						/user/{print ct, "lxc.cgroup.cpuacct.stat.user", $2/100}
					' ;;
				*) echo "$1 lxc.cgroup.$i $cgdata" ;;
			esac
		fi
	done
}


lxc_attach() {
	[ "$(lxc-info -s -n $CTID | awk '{print $2}')" = "RUNNING" ] || exit 0
	lxc-attach -n $CTID -- df -P / 2>/dev/null | awk -v ct=$1 '
		{
			if($NF~"/") print ct, "lxc.attach.df.size", $2
			if($NF~"/") print ct, "lxc.attach.df.used", $3
			if($NF~"/") print ct, "lxc.attach.df.free", $4
		}'
}


zabbix_send() {
	local ARG='>/dev/null'
	[ "$ZABBIX_SENDER_DEBUG" = 1 ] && ARG="-vv >>/var/log/zabbix-agent/$(basename $0).log"
	eval $ZABBIX_SENDER --config $ZABBIX_CONFIG --input-file - $ARG 2>&1
}


[ -n "$2" ] && CTID=`echo $2 | sed "s|^$(hostname)\.||"`
case $1 in
	'discover') discover ;;
	'info') lxc_info $2 | zabbix_send ;;
	'cgroup') lxc_cgroup $2 | zabbix_send ;;
	'attach') lxc_attach $2 | zabbix_send ;;
	*) exit 1 ;;
esac
