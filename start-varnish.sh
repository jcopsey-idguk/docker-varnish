#!/bin/bash

DAEMON_OPTS="-F \
             -P ${PIDFILE:-/var/run/varnish.pid} \
             -a ${VARNISH_LISTEN_ADDRESS:-0.0.0.0}:${VARNISH_LISTEN_PORT:-80} \
             -f ${VARNISH_VCL_CONF:-/etc/varnish/docker-default.vcl} \
             -T ${VARNISH_ADMIN_LISTEN_ADDRESS:-127.0.0.1}:${VARNISH_ADMIN_LISTEN_PORT:-6082} \
             -t ${VARNISH_TTL:-120} \
             -p thread_pool_min=${VARNISH_MIN_THREADS:-50} \
	     -p thread_pool_max=${VARNISH_MAX_THREADS:-1000} \
	     -p thread_pool_timeout=${VARNISH_THREAD_TIMEOUT:-120} \
             -u ${VARNISH_USER:-varnish} -g ${VARNISH_GROUP:-varnish} \
             -S ${VARNISH_SECRET_FILE:-/etc/varnish/secret} \
             -s ${VARNISH_STORAGE:-file,/var/lib/varnish/varnish_storage.bin,1G} \
	     -p timeout_req=10 -p timeout_idle=10"

echo -n "Starting Varnish Cache: "
echo ${DAEMON_OPTS}

/usr/sbin/varnishd ${DAEMON_OPTS}
