#!/usr/bin/env bash
set -Eeuo pipefail

# shellcheck disable=SC2209
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
# red="${cli}1;31m"
yellow="${cli}1;33m"
green="${cli}1;32m"

# Variables
TZ=${TZ:-UTC}
PUID=${PUID:-1000}
PGID=${PGID:-1000}
CLIENT=${CLIENT:-no}
LISTEN_HOST=${LISTEN_HOST:-0.0.0.0}
LISTEN_PORT=${LISTEN_PORT:-853}
CONNECT_HOST=${CONNECT_HOST:-10.0.0.1}
CONNECT_PORT=${CONNECT_PORT:-53}
HEALTHCHECK=${HEALTHCHECK:-127.0.0.1}

echo -e "\n${bold}Starting Stunnel for Docker...${norm} ($LISTEN_HOST:$LISTEN_PORT => $CONNECT_HOST:$CONNECT_PORT)\n"

# Timezone
echo "  ${norm}[${green}+${norm}] Setting timezone to ${green}${TZ}${norm}"
ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
echo "${TZ}" > /etc/timezone

cert="/stunnel.pem"

if [ -d "$cert" ]; then

    echo "The bind $cert maps to a file that does not exist!"
    exit 1

fi

# Check certificate & key
if [ -f "$cert" ] && [ -s "$cert" ]; then
  cp "$cert" /etc/stunnel/stunnel.pem
  chmod 640 /etc/stunnel/stunnel.pem
  rm -f  /etc/stunnel/stunnel.crt
  rm -f  /etc/stunnel/stunnel.key
  openssl pkey -in  /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.key
  openssl x509 -outform PEM -in  /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.crt
  rm /etc/stunnel/stunnel.pem
fi

if [ ! -f /etc/stunnel/stunnel.crt ] || [ ! -f /etc/stunnel/stunnel.key ]; then
  echo -e "  ${norm}[${yellow}+${norm}] Generating self-signed certificate..."
  openssl ecparam -genkey -name prime256v1 -out /etc/stunnel/stunnel.key
  openssl req -new -x509 -sha512 -nodes -days 3652 \
    -subj "/C=FR/ST=SSL/L=SSL/O=SSL/CN=SSL" \
    -key /etc/stunnel/stunnel.key -out /etc/stunnel/stunnel.crt
fi

chmod 640 /etc/stunnel/stunnel.crt
chmod 640 /etc/stunnel/stunnel.key

# Check configuration

config="/stunnel.conf"

if [ -d "$config" ]; then

    echo "The bind $config maps to a file that does not exist!"
    exit 1

fi

if [ -f "$config" ] && [ -s "$config" ]; then
  cp "$config" /etc/stunnel/stunnel.conf
else
  config="/etc/stunnel/stunnel.conf"
  rm -f "$config"

  echo "  ${norm}[${green}+${norm}] Setting up stunnel configuration.."
  cat > "$config" << EOF
foreground = yes
output = /var/log/stunnel.log

[Client]
client = $CLIENT
accept = $LISTEN_HOST:$LISTEN_PORT
connect = $CONNECT_HOST:$CONNECT_PORT

delay = no
renegotiation = no
sslVersionMin = TLSv1.2
sslVersionMax = TLSv1.3

key=/etc/stunnel/stunnel.key
cert=/etc/stunnel/stunnel.crt

socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
socket = r:TCP_KEEPCNT=4
socket = r:TCP_KEEPIDLE=40
socket = r:TCP_KEEPINTVL=5
socket = r:SO_KEEPALIVE=1
EOF
fi

# Fix permissions
echo -e "  ${norm}[${green}+${norm}] Fixing permissions..${norm}\n"
chown "${PUID}:${PGID}" /proc/self/fd/1 /proc/self/fd/2
chown -R "${PUID}:${PGID}" /etc/stunnel /var/log/stunnel.log

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
exec /usr/bin/stunnel
