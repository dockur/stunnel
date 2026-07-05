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
LISTEN_PORT=${LISTEN_PORT:-853}
CONNECT_HOST=${CONNECT_HOST:-10.0.0.1}
CONNECT_PORT=${CONNECT_PORT:-53}
HEALTHCHECK=${HEALTHCHECK:-127.0.0.1}

detectListenHost() {
  if [ -f /proc/net/if_inet6 ] && [[ "$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6 2>/dev/null)" != "1" ]]; then
    LISTEN_HOST=${LISTEN_HOST:-::}
  else
    LISTEN_HOST=${LISTEN_HOST:-0.0.0.0}
  fi
}

configureTimezone() {
  # Timezone
  echo "  ${norm}[${green}+${norm}] Setting timezone to ${green}${TZ}${norm}"
  ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  echo "${TZ}" > /etc/timezone
}

checkBindIsFile() {
  local path="$1"

  if [ -d "$path" ]; then
    echo "The bind $path maps to a file that does not exist!"
    exit 1
  fi
}

selectCertificateFile() {
  cert="/cert.pem"
  checkBindIsFile "$cert"

  if [ ! -f "$cert" ] || [ ! -s "$cert" ]; then

    cert="/cert.crt"
    checkBindIsFile "$cert"

  fi
}

selectPrivateKeyFile() {
  key="/private.pem"
  checkBindIsFile "$key"

  if [ ! -f "$key" ] || [ ! -s "$key" ]; then

    key="/private.key"
    checkBindIsFile "$key"

  fi
}

generateCertificate() {
  cert="/etc/stunnel/cert.crt"
  key="/etc/stunnel/private.key"

  echo -e "  ${norm}[${yellow}+${norm}] Generating self-signed certificate..."
  openssl ecparam -genkey -name prime256v1 -out "$key"
  openssl req -new -x509 -sha512 -nodes -days 3652 \
    -subj "/C=FR/ST=SSL/L=SSL/O=SSL/CN=SSL" \
    -key "$key" -out "$cert"
}

processCertificates() {
  # Process certificates
  selectCertificateFile
  selectPrivateKeyFile

  if [ ! -f "$cert" ] || [ ! -s "$cert" ] || [ ! -f "$key" ] || [ ! -s "$key" ]; then
    generateCertificate
  fi
}

writeDefaultConfig() {
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

key=$key
cert=$cert

socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
socket = r:TCP_KEEPCNT=4
socket = r:TCP_KEEPIDLE=40
socket = r:TCP_KEEPINTVL=5
socket = r:SO_KEEPALIVE=1
EOF
}

configureStunnel() {
  # Check configuration
  config="/stunnel.conf"
  checkBindIsFile "$config"

  if [ -f "$config" ] && [ -s "$config" ]; then
    cp "$config" /etc/stunnel/stunnel.conf
  else
    writeDefaultConfig
  fi
}

fixPermissions() {
  # Fix permissions
  echo -e "  ${norm}[${green}+${norm}] Fixing permissions..${norm}\n"

  # Do not fail startup if stdout/stderr cannot be chowned.
  chown "${PUID}:${PGID}" /proc/self/fd/1 /proc/self/fd/2 2>/dev/null || :
  chown -R "${PUID}:${PGID}" /etc/stunnel /var/log/stunnel.log

  if [ -n "${PGID}" ] && [ -n "${PUID}" ]; then
    sed -i -e "s/^stunnel:\([^:]*\):[0-9]*/stunnel:\1:${PGID}/" /etc/group
    sed -i -e "s/^stunnel:\([^:]*\):\([0-9]*\):[0-9]*/stunnel:\1:\2:${PGID}/" /etc/passwd
    sed -i -e "s/^stunnel:\([^:]*\):[0-9]*:\([0-9]*\)/stunnel:\1:${PUID}:\2/" /etc/passwd
  fi
}

writeHealthcheck() {
  # Healthcheck
  cat > /usr/local/bin/healthcheck << EOF
#!/usr/bin/env sh
set -e
nc -w 1 -z "$HEALTHCHECK" "$LISTEN_PORT"
EOF
  chmod +x /usr/local/bin/healthcheck
}

detectListenHost

echo -e "\n${bold}Starting Stunnel for Docker...${norm} ($LISTEN_HOST:$LISTEN_PORT => $CONNECT_HOST:$CONNECT_PORT)\n"

configureTimezone
processCertificates
configureStunnel
fixPermissions
writeHealthcheck

# Init
exec /usr/bin/stunnel
