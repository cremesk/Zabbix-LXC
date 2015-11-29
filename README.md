# Description
LXC node monitoring through Zabbix.

LXC containers monitoring through Zabbix.

Template "Template LXC Node" finds all containers, creates new hosts and apply template "Template LXC CT" on them.

# Dependencies
sudo, zabbix-agent, zabbix-sender.

# Installation
```
mkdir /etc/zabbix/scripts
chmod 755 /etc/zabbix/scripts
cp zabbix/scripts/lxc.sh /etc/zabbix/scripts
chmod 644 /etc/zabbix/scripts/lxc.sh
cp zabbix/zabbix_agentd.d/lxc.conf /etc/zabbix/zabbix_agentd.d/
cp sudoers.d/zabbix /etc/sudoers.d/
chown root:root /etc/sudoers.d/zabbix
chmod 440 /etc/sudoers.d/zabbix
service zabbix-agent restart
```

## Optional add `sudo` rules via `visudo`
Add `visudo` rule by command:
```
visudo -f /etc/sudoers.d/zabbix
```

And add rule line:
```
zabbix ALL=NOPASSWD:/bin/sh /etc/zabbix/scripts/lxc-info.sh *
```

Go to zabbix web gui and import "zbx_templates/Template_LXC_CT.xml" and "zbx_templates/Template_LXC_Node.xml" into your templates.

Apply template "Template LXC Node" to LXC hardware node (otherwise known as host system).


# If you do not want discovery containers:
1. Do not import template "Template LXC Node.xml".

2. Create host in zabbix with name in format: `lxc_host.lxc_container`, where `lxc_host` - hostname you LXC hardware node, `lxc_container` - hostname LXC container.

3. Apply template "Template_LXC_CT" manually for new host.
