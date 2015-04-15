FROM		centos:7
RUN		yum -y update && yum -y install epel-release && yum -y install varnish && yum -y clean all
ADD		mw.vcl /etc/varnish/mw.vcl
ADD		start-varnish.sh /usr/local/bin/start-varnish.sh
RUN		chmod +x /usr/local/bin/start-varnish.sh

ENV		VARNISH_VCL_CONF=/etc/varnish/mw.vcl \
		VARNISH_LISTEN_PORT=80 \
		VARNISH_ADMIN_LISTEN_ADDRESS=127.0.0.1 \
		VARNISH_ADMIN_LISTEN_PORT=6082 \  
		VARNISH_SECRET_FILE=/etc/varnish/secret \
		VARNISH_STORAGE="file,/var/lib/varnish/varnish_storage.bin,5G" \
		VARNISH_TTL=120 \
		VARNISH_USER=varnish \
		VARNISH_GROUP=varnish

EXPOSE		80 6082
ENTRYPOINT	/usr/local/bin/start-varnish.sh
#ENTRYPOINT	/usr/sbin/varnishd -p timeout_req=10 -p timeout_idle=10
#ENTRYPOINT     ["bash"]
