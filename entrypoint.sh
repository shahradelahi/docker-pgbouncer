#!/usr/bin/env bash

set -e

# Inspired By https://github.com/edoburu/docker-pgbouncer/blob/master/entrypoint.sh

PG_CONFIG_DIR="${PG_CONFIG_DIR:-/etc/pgbouncer}"
CONFIG_FILE="${PG_CONFIG_DIR}/pgbouncer.ini"
AUTH_FILE="${PG_CONFIG_DIR}/userlist.txt"

export PGBOUNCER_INI=${CONFIG_FILE}

add_db_line() {
  local record="$1 = $2"
  sed -i "s/^\[databases\]/\[databases\]\n$record/" "$PGBOUNCER_INI"
}

check_db_exists() {
  local dbname=$1
  if grep -q "^$dbname" "$PGBOUNCER_INI"; then
    return 0
  else
    return 1
  fi
}

add_auth_user() {
  if grep -q "^\"${1}\"" "${AUTH_FILE}"; then
    echo "User ${1} not added auth file."
  else
    echo "\"${username}\" \"${!var}\"" >> "${AUTH_FILE}"
  fi
}

refine_config(){
  # Remove extra space and tabs from end of lines
  sed -i 's/[ \t]*$//' "$PGBOUNCER_INI"

  # Remove options with empty values
  sed -i '/=$/d' "$PGBOUNCER_INI"

  # Remove all comments and empty lines from config file
  sed -i '/^;/d' "$CONFIG_FILE"
  sed -i '/^$/N;/^\n$/D' "$PGBOUNCER_INI"

  # Remove empty lines from start and end of file
  sed -i -e '/./,$!d' -e :a -e '/^\n*$/{$d;N;};/\n$/ba' "$PGBOUNCER_INI"
}

generate_config() {
  echo "Generating PgBouncer config in ${CONFIG_FILE}"

  printf "\
;;;;; AUTO-GENERATED FILE, DO NOT EDIT ;;;;;

;;;
;;; PgBouncer configuration file
;;;

;; Database section
;;
;; Available configuration parameters:
;;   dbname= host= port= user= password= auth_user=
;;   client_encoding= datestyle= timezone=
;;   pool_size= reserve_pool= max_db_connections=
;;   pool_mode= connect_query= application_name=
[databases]

;; redirect bardb to bazdb on localhost
;bardb = host=localhost dbname=bazdb

;; access to dest database will go with single user
;forcedb = host=localhost port=300 user=baz password=foo client_encoding=UNICODE datestyle=ISO connect_query='SELECT 1'

;; use custom pool sizes
;nondefaultdb = pool_size=50 reserve_pool=10

;; User-specific configuration
[users]

;user1 = pool_mode=transaction max_user_connections=10

;; Configuration section
[pgbouncer]

;;;
;;; Administrative settings
;;;
logfile = ${LOGFILE:-/var/log/pgbouncer/pgbouncer.log}
${PIDFILE:+pidfile = ${PIDFILE}\n}\
user = pgbouncer

;;;
;;; Where to wait for clients
;;;

;; IP address or * which means all IPs
listen_addr = ${LISTEN_ADDR:-0.0.0.0}
listen_port = ${LISTEN_PORT:-6432}

;; Unix socket is also used for -R.
${UNIX_SOCKET_DIR:+unix_socket_dir = ${UNIX_SOCKET_DIR}\n}\
${UNIX_SOCKET_MODE:+unix_socket_mode = ${UNIX_SOCKET_MODE}\n}\
${UNIX_SOCKET_GROUP:+unix_socket_group = ${UNIX_SOCKET_GROUP}\n}\
${PEER_ID:+peer_id = ${PEER_ID}\n}\


;;;
;;; TLS settings for accepting clients
;;;
${CLIENT_TLS_SSLMODE:+client_tls_sslmode = ${CLIENT_TLS_SSLMODE}\n}\
${CLIENT_TLS_CA_FILE:+client_tls_ca_file = ${CLIENT_TLS_CA_FILE}\n}\
${CLIENT_TLS_KEY_FILE:+client_tls_key_file = ${CLIENT_TLS_KEY_FILE}\n}\
${CLIENT_TLS_CERT_FILE:+client_tls_cert_file = ${CLIENT_TLS_CERT_FILE}\n}\
${CLIENT_TLS_CIPHERS:+client_tls_ciphers = ${CLIENT_TLS_CIPHERS}\n}\
${CLIENT_TLS_PROTOCOLS:+client_tls_protocols = ${CLIENT_TLS_PROTOCOLS}\n}\
${CLIENT_TLS_DHEPARAMS:+client_tls_dheparams = ${CLIENT_TLS_DHEPARAMS}\n}\
${CLIENT_TLS_ECDHCURVE:+client_tls_ecdhcurve = ${CLIENT_TLS_ECDHCURVE}\n}\


;;;
;;; TLS settings for connecting to backend databases
;;;
${SERVER_TLS_SSLMODE:+server_tls_sslmode = ${SERVER_TLS_SSLMODE}\n}\
${SERVER_TLS_CA_FILE:+server_tls_ca_file = ${SERVER_TLS_CA_FILE}\n}\
${SERVER_TLS_KEY_FILE:+server_tls_key_file = ${SERVER_TLS_KEY_FILE}\n}\
${SERVER_TLS_CERT_FILE:+server_tls_cert_file = ${SERVER_TLS_CERT_FILE}\n}\
${SERVER_TLS_PROTOCOLS:+server_tls_protocols = ${SERVER_TLS_PROTOCOLS}\n}\
${SERVER_TLS_CIPHERS:+server_tls_ciphers = ${SERVER_TLS_CIPHERS}\n}\


;;;
;;; Authentication settings
;;;
auth_type = ${AUTH_TYPE:-scram-sha-256}
auth_file = ${AUTH_FILE}
${AUTH_HBA_FILE:+auth_hba_file = ${AUTH_HBA_FILE}\n}\
${AUTH_QUERY:+auth_query = ${AUTH_QUERY}\n}\
${AUTH_DBNAME:+auth_dbname = ${AUTH_DBNAME}\n}\


;;;
;;; Users allowed into database 'pgbouncer'
;;;
admin_users = ${ADMIN_USERS:-}
stats_users = ${STATS_USERS:-}


;;;
;;; Pooler personality questions
;;;
${POOL_MODE:+pool_mode = ${POOL_MODE}\n}\
${MAX_PREPARED_STATEMENTS:+max_prepared_statements = ${MAX_PREPARED_STATEMENTS}\n}\
${SERVER_RESET_QUERY:+server_reset_query = ${SERVER_RESET_QUERY}\n}\
${SERVER_RESET_QUERY_ALWAYS:+server_reset_query_always = ${SERVER_RESET_QUERY_ALWAYS}\n}\
${TRACK_EXTRA_PARAMETERS:+track_extra_parameters = ${TRACK_EXTRA_PARAMETERS}\n}\
ignore_startup_parameters = ${IGNORE_STARTUP_PARAMETERS:-extra_float_digits}
${SERVER_CHECK_QUERY:+server_check_query = ${SERVER_CHECK_QUERY}\n}\
${SERVER_CHECK_DELAY:+server_check_delay = ${SERVER_CHECK_DELAY}\n}\
${SERVER_FAST_CLOSE:+server_fast_close = ${SERVER_FAST_CLOSE}\n}\
${APPLICATION_NAME_ADD_HOST:+application_name_add_host = ${APPLICATION_NAME_ADD_HOST}\n}\
${STATS_PERIOD:+stats_period = ${STATS_PERIOD}\n}\


;;;
;;; Connection limits
;;;
${MAX_CLIENT_CONN:+max_client_conn = ${MAX_CLIENT_CONN}\n}\
${DEFAULT_POOL_SIZE:+default_pool_size = ${DEFAULT_POOL_SIZE}\n}\
${MIN_POOL_SIZE:+min_pool_size = ${MIN_POOL_SIZE}\n}\
${RESERVE_POOL_SIZE:+reserve_pool_size = ${RESERVE_POOL_SIZE}\n}\
${RESERVE_POOL_TIMEOUT:+reserve_pool_timeout = ${RESERVE_POOL_TIMEOUT}\n}\
${MAX_DB_CONNECTIONS:+max_db_connections = ${MAX_DB_CONNECTIONS}\n}\
${MAX_USER_CONNECTIONS:+max_user_connections = ${MAX_USER_CONNECTIONS}\n}\
${SERVER_ROUND_ROBIN:+server_round_robin = ${SERVER_ROUND_ROBIN}\n}\


;;;
;;; Logging
;;;
${SYSLOG:+syslog = ${SYSLOG}\n}\
${SYSLOG_FACILITY:+syslog_facility = ${SYSLOG_FACILITY}\n}\
${SYSLOG_IDENT:+syslog_ident = ${SYSLOG_IDENT}\n}\
${LOG_CONNECTIONS:+log_connections = ${LOG_CONNECTIONS}\n}\
${LOG_DISCONNECTIONS:+log_disconnections = ${LOG_DISCONNECTIONS}\n}\
${LOG_POOLER_ERRORS:+log_pooler_errors = ${LOG_POOLER_ERRORS}\n}\
${LOG_STATS:+log_stats = ${LOG_STATS}\n}\
${VERBOSE:+verbose = ${VERBOSE}\n}\


;;;
;;; Timeouts
;;;
${SERVER_LIFETIME:+server_lifetime = ${SERVER_LIFETIME}\n}\
${SERVER_IDLE_TIMEOUT:+server_idle_timeout = ${SERVER_IDLE_TIMEOUT}\n}\
${SERVER_CONNECT_TIMEOUT:+server_connect_timeout = ${SERVER_CONNECT_TIMEOUT}\n}\
${SERVER_LOGIN_RETRY:+server_login_retry = ${SERVER_LOGIN_RETRY}\n}\
${QUERY_TIMEOUT:+query_timeout = ${QUERY_TIMEOUT}\n}\
${QUERY_WAIT_TIMEOUT:+query_wait_timeout = ${QUERY_WAIT_TIMEOUT}\n}\
${CANCEL_WAIT_TIMEOUT:+cancel_wait_timeout = ${CANCEL_WAIT_TIMEOUT}\n}\
${CLIENT_IDLE_TIMEOUT:+client_idle_timeout = ${CLIENT_IDLE_TIMEOUT}\n}\
${CLIENT_LOGIN_TIMEOUT:+client_login_timeout = ${CLIENT_LOGIN_TIMEOUT}\n}\
${AUTODB_IDLE_TIMEOUT:+autodb_idle_timeout = ${AUTODB_IDLE_TIMEOUT}\n}\
${IDLE_TRANSACTION_TIMEOUT:+idle_transaction_timeout = ${IDLE_TRANSACTION_TIMEOUT}\n}\
${SUSPEND_TIMEOUT:+suspend_timeout = ${SUSPEND_TIMEOUT}\n}\


;;;
;;; Low-level tuning options
;;;
${PKT_BUF:+pkt_buf = ${PKT_BUF}\n}\
${LISTEN_BACKLOG:+listen_backlog = ${LISTEN_BACKLOG}\n}\
${SBUF_LOOPCNT:+sbuf_loopcnt = ${SBUF_LOOPCNT}\n}\
${MAX_PACKET_SIZE:+max_packet_size = ${MAX_PACKET_SIZE}\n}\
${SO_REUSEPORT:+so_reuseport = ${SO_REUSEPORT}\n}\
${TCP_DEFER_ACCEPT:+tcp_defer_accept = ${TCP_DEFER_ACCEPT}\n}\
${TCP_SOCKET_BUFFER:+tcp_socket_buffer = ${TCP_SOCKET_BUFFER}\n}\
${TCP_KEEPALIVE:+tcp_keepalive = ${TCP_KEEPALIVE}\n}\
${TCP_KEEPCNT:+tcp_keepcnt = ${TCP_KEEPCNT}\n}\
${TCP_KEEPIDLE:+tcp_keepidle = ${TCP_KEEPIDLE}\n}\
${TCP_KEEPINTVL:+tcp_keepintvl = ${TCP_KEEPINTVL}\n}\
${TCP_USER_TIMEOUT:+tcp_user_timeout = ${TCP_USER_TIMEOUT}\n}\
${DNS_MAX_TTL:+dns_max_ttl = ${DNS_MAX_TTL}\n}\
${DNS_ZONE_CHECK_PERIOD:+dns_zone_check_period = ${DNS_ZONE_CHECK_PERIOD}\n}\
${DNS_NXDOMAIN_TTL:+dns_nxdomain_ttl = ${DNS_NXDOMAIN_TTL}\n}\
${RESOLV_CONF:+resolv_conf = ${RESOLV_CONF}\n}\


;;;
;;; Random stuff
;;;
${DISABLE_PQEXEC:+disable_pqexec = ${DISABLE_PQEXEC}\n}\

;;;;;;; END OF FILE ;;;;;;;
" > "$CONFIG_FILE"

  # get all env vars starting with DB_URL_
  for var in $(env | grep -E "^DB_URL_" | cut -d= -f1); do
    # get the value of the env var
    db_url="${!var}"
    IFS=' ' read -ra parsed <<< "$(parse-conn ${db_url})"

    echo "Adding ${db_url} to ${CONFIG_FILE} to databases section."
    add-db "$db_url"
  done

  ###
  # DATABASE_URL is a special env var that can parse a postgres connection url and
  # add it to the config file.
  #
  # Example:
  #   DATABASE_URL="postgres://user:pass@host:5432/dbname"
  ###
  if [ -n "${DATABASE_URL}" ]; then
    echo "Adding ${DATABASE_URL} to ${CONFIG_FILE} as default database."
    add-db "${DATABASE_URL}"
  fi

  ###
  # Support for DB_{HOST,PORT,USER,PASSWORD,NAME} env vars. this feature
  # can not be used with "DATABASE_URL" env var.
  #
  # Parameters:
  #   required: DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME
  #   extra: CLIENT_ENCODING, POOL_SIZE, TIMEZONE, POOL_SIZE, RESERVE_POOL, MAX_DB_CONNECTIONS, POOL_MODE, CONNECT_QUERY, APPLICATION_NAME
  ###
  if [ -n "${DB_HOST}" ] && [ -n "${DB_PORT}" ] && [ -n "${DB_USER}" ] && [ -n "${DB_PASSWORD}" ] && [ -n "${DB_NAME}" ]; then
    echo "Adding ${DB_HOST}:${DB_PORT} to ${CONFIG_FILE} as ${DB_NAME} database."
    if check_db_exists "${DB_NAME}"; then
      echo "Database ${DB_NAME} already exists in ${CONFIG_FILE}."
    else
      add_db_line "${DB_NAME}" "host=${DB_HOST} port=${DB_PORT} dbname=${DB_NAME} user=${DB_USER} password=${DB_PASSWORD}${CLIENT_ENCODING:+ client_encoding=${CLIENT_ENCODING}}${TIMEZONE:+ timezone=${TIMEZONE}}${POOL_SIZE:+ pool_size=${POOL_SIZE}}${RESERVE_POOL:+ reserve_pool=${RESERVE_POOL}}${MAX_DB_CONNECTIONS:+ max_db_connections=${MAX_DB_CONNECTIONS}}${POOL_MODE:+ pool_mode=${POOL_MODE}}${CONNECT_QUERY:+ connect_query=${CONNECT_QUERY}}${APPLICATION_NAME:+ application_name=${APPLICATION_NAME}}"
    fi
  fi

  ###
  # Support for DB_<NAME> env vars
  #
  # Example:
  #   DB_BAZ="host=localhost port=5432 dbname=bazdb"
  ###
  for var in $(env | grep -E "^DB_" | cut -d= -f1); do
    # exclude DB_URL_, DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME
    if [[ ! $var =~ ^DB_URL_ ]] && [[ ! $var =~ ^DB_HOST ]] && [[ ! $var =~ ^DB_PORT ]] && [[ ! $var =~ ^DB_USER ]] && [[ ! $var =~ ^DB_PASSWORD ]] && [[ ! $var =~ ^DB_NAME ]]; then
      # dbname = DB_BAZ -> baz
      db_name=$(echo "${var}" | cut -d_ -f2 | tr '[:upper:]' '[:lower:]')
      # add db to config
      echo "Adding ${!var} to ${CONFIG_FILE} as ${db_name} database."
      add_db_line "${db_name}" "${!var}"
    fi
  done

  ###
  # Support for ADMIN_{USER,PASSWORD} env vars
  #
  # Example:
  #   ADMIN_USER="user1"
  ###
  if [ -n "${ADMIN_USER}" ]; then
    echo "Adding ${ADMIN_USER} to ${CONFIG_FILE} as admin user."
    sed -i "s/^admin_users =.*/admin_users = ${ADMIN_USER},/" "$CONFIG_FILE"
    sed -i "s/^stats_users =.*/stats_users = ${ADMIN_USER},/" "$CONFIG_FILE"
    # add user to auth file
    echo "\"${ADMIN_USER}\" \"${ADMIN_PASSWORD:-}\"" >> "${AUTH_FILE}"
    # remove , from end of line
    sed -i "s/, *$//" "$CONFIG_FILE"
  fi

  refine_config
}

echo "                                                   "
echo "    ___        ___                                 "
echo "   / _ \__ _  / __\ ___  _   _ _ __   ___ ___ _ __ "
echo "  / /_)/ _\` |/__\/// _ \\| | | | '_ \ / __/ _ \ '__|"
echo " / ___/ (_| / \/  \\ (_) | |_| | | | | (_|  __/ |   "
echo " \\/    \\__, \\_____/\\___/ \\__,_|_| |_|\___\___|_|   "
echo "       |___/                                       "
echo "                                                   "

# Create config directory
if [ ! -d ${PG_CONFIG_DIR} ]; then
  mkdir -p ${PG_CONFIG_DIR}
fi

# Create userlist.txt if not exists
if [ ! -e "${AUTH_FILE}" ]; then
  touch "${AUTH_FILE}"
fi

# Create pgbouncer.ini if not exists
if [ ! -f ${CONFIG_FILE} ]; then
  generate_config
else
  echo "Using existing pgbouncer config in ${CONFIG_FILE}"
fi

# Get USER_<name> env vars and add them to auth file
for var in $(env | grep -E "^USER_" | cut -d= -f1); do
  # username = USER_BAZ -> baz
  username=$(echo "${var}" | cut -d_ -f2 | tr '[:upper:]' '[:lower:]')
  add_auth_user "${username}"
done

sleep 1
echo -e "\n======================== Versions ========================"
echo -e "Alpine: \c" && cat /etc/alpine-release
echo -e "PgBouncer: \c" && pgbouncer -V
echo -e "\n==================== PgBouncer Config ===================="
cat ${CONFIG_FILE}
echo -e "========================================================\n"
sleep 1

exec "$@"