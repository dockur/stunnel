#!/bin/sh

echo=echo
for cmd in echo /bin/echo; do
	$cmd >/dev/null 2>&1 || continue
	if ! $cmd -e "" | grep -qE '^-e'; then
		echo=$cmd
		break
	fi
done

cli=$($echo -e "\033[")
norm="${cli}0m"
bold="${cli}1;37m"
red="${cli}1;31m"
yellow="${cli}1;33m"
green="${cli}1;32m"

# Variables
TZ=${TZ:-UTC}
LISTEN_HOST=${LISTEN_HOST:-0.0.0.0}
LISTEN_PORT=${LISTEN_PORT:-389}
CONNECT_HOST=${CONNECT_HOST:-ldap.google.com}
CONNECT_PORT=${CONNECT_PORT:-636}
HEALTHCHECK=${HEALTHCHECK:-127.0.0.1}

echo -e "\n${bold}Docker Stunnel${norm} ($LISTEN_HOST:$LISTEN_PORT => $CONNECT_HOST:$CONNECT_PORT)\n"

# Timezone
echo "  ${norm}[${green}+${norm}] Setting timezone to ${green}${TZ}${norm}"
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# Check configuration
if [ ! -f /etc/stunnel/stunnel.conf ]; then
	echo "  ${norm}[${green}+${norm}] Setting stunnel configuration"
	cat > /etc/stunnel/stunnel.conf << EOF
output = /var/log/stunnel.log
foreground = yes

[Client]
client = yes
accept = $LISTEN_HOST:$LISTEN_PORT
connect = $CONNECT_HOST:$CONNECT_PORT

cert=/etc/stunnel/stunnel.crt
key=/etc/stunnel/stunnel.key
sslVersionMin = TLSv1.2
sslVersionMax = TLSv1.3
renegotiation = no
delay = yes

socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
socket = r:TCP_KEEPCNT=4
socket = r:TCP_KEEPIDLE=40
socket = r:TCP_KEEPINTVL=5
socket = r:SO_KEEPALIVE=1
EOF
fi

# Check certificate & key
if [ ! -f /etc/stunnel/stunnel.crt ] || [ ! -f /etc/stunnel/stunnel.key ]; then
  echo -e "  ${norm}[${yellow}+${norm}] Setting certificate & key (missing)"
  openssl ecparam -genkey -name prime256v1 -out /etc/stunnel/stunnel.key
  openssl req -new -x509 -sha512 -nodes -days 3652 \
  -subj "/C=FR/ST=SSL/L=SSL/O=SSL/CN=SSL" \
  -key /etc/stunnel/stunnel.key -out /etc/stunnel/stunnel.crt
fi

# Fix permissions
echo -e "  ${norm}[${green}+${norm}] Fix permissions${norm}\n"
chown ${PUID}:${PGID} /proc/self/fd/1 /proc/self/fd/2
chown -R ${PUID}:${PGID} /etc/stunnel /var/log/stunnel.log
chmod 640 /etc/stunnel/stunnel.key

if [ -n "${PGID}" ] && [ -n "${PUID}" ]; then
  sed -i -e "s/^stunnel:\([^:]*\):[0-9]*/stunnel:\1:${PGID}/" /etc/group
  sed -i -e "s/^stunnel:\([^:]*\):\([0-9]*\):[0-9]*/stunnel:\1:\2:${PGID}/" /etc/passwd
  sed -i -e "s/^stunnel:\([^:]*\):[0-9]*:\([0-9]*\)/stunnel:\1:${PUID}:\2/" /etc/passwd
fi

# Healthcheck
cat > /usr/local/bin/healthcheck << EOF
#!/usr/bin/env sh
set -e
nc -w 1 -z $HEALTHCHECK $LISTEN_PORT
EOF
chmod +x /usr/local/bin/healthcheck

# Init
su -s /usr/bin/stunnel stunnel
