FROM debian:testing-backports

RUN apt-get update \
 && apt-get install -y wget \
 && apt-get install -y sudo \
 && apt-get install -y squidguard \
 && apt-get install -y apache2

ENV SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_USER=proxy \
    UPDATE_BLACKLIST_URL=http://www.shallalist.de/Downloads/shallalist.tar.gz

RUN echo 'AddType application/x-ns-proxy-autoconfig .dat' >> /etc/apache2/httpd.conf
ADD wpad.dat /var/www/html/wpad.dat
ADD block.html /var/www/html/block.html

ADD shalla_update.v2.sh /etc/cron.daily/shalla_update.sh
RUN chmod 755 /etc/cron.daily/shalla_update.sh

RUN sed -i '/http_access allow localnet/s/^#//g' /etc/squid/squid.conf
RUN echo "dns_v4_first on" >> /etc/squid/squid.conf
RUN echo "dns_nameservers 192.168.2.1 192.168.2.7" >> /etc/squid/squid.conf
RUN echo "ignore_unknown_nameservers off" >> /etc/squid/squid.conf
RUN echo "request_header_access Referer deny all" >> /etc/squid/squid.conf
#RUN echo "forward_max_tries 25" >> /etc/squid/squid.conf
RUN echo "redirect_program /usr/bin/squidGuard -c /etc/squidguard/squidGuard.conf" >> /etc/squid/squid.conf
RUN echo "access_log daemon:/custom-config/logs/access.log squid" >> /etc/squid/squid.conf
RUN echo "cache_dir ufs /var/spool/squid 100 16 256" >> /etc/squid/squid.conf
RUN echo "cache_store_log stdio:/custom-config/logs/cache.log" >> /etc/squid/squid.conf
RUN echo "memory_cache_mode always" >> /etc/squid/squid.conf
RUN echo "max_stale 1 day"  >> /etc/squid/squid.conf
RUN echo "ipcache_size 1024" >> /etc/squid/squid.conf
RUN echo "ipcache_low 90" >> /etc/squid/squid.conf
RUN echo "ipcache_high 95" >> /etc/squid/squid.conf
RUN echo "cache_mem 512 MB" >> /etc/squid/squid.conf
RUN echo "acl snmpnet src 127.0.0.1" >> /etc/squid/squid.conf
RUN echo "acl snmpnet src 192.168.2.7" >> /etc/squid/squid.conf
RUN echo "acl snmpnet src 192.168.2.1" >> /etc/squid/squid.conf
RUN echo "acl snmppublic snmp_community public" >> /etc/squid/squid.conf
RUN echo "snmp_port 3401" >> /etc/squid/squid.conf
RUN echo "snmp_access allow snmppublic snmpnet" >> /etc/squid/squid.conf
RUN echo "snmp_access deny all" >> /etc/squid/squid.conf

RUN rm /etc/squidguard/squidGuard.conf
ADD sample-config-blacklist /sample-config-blacklist
ADD sample-config-simple /sample-config-simple
RUN mkdir /custom-config

ADD entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

ADD startSquidGuard /startSquidGuard
RUN chmod a+x /startSquidGuard

EXPOSE 3128 80
VOLUME [ "/var/log/squid" ]
VOLUME [ "/custom-config" ]
VOLUME [ "/var/lib/squidguard/db" ]

CMD [ "/startSquidGuard" ]
