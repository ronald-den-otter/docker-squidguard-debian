FROM debian:testing-backports

RUN apt-get update \
 && apt-get install -y wget \ 
 && apt-get install -y sudo \ 
 && apt-get install -y squidguard \ 
 && apt-get install -y apache2

ENV SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_USER=proxy

RUN echo 'AddType application/x-ns-proxy-autoconfig .dat' >> /etc/apache2/httpd.conf
ADD wpad.dat /var/www/html/wpad.dat
ADD block.html /var/www/html/block.html

RUN sed -i '/http_access allow localnet/s/^#//g' /etc/squid/squid.conf
RUN echo "dns_v4_first on" >> /etc/squid/squid.conf
RUN echo "forward_max_tries 25" >> /etc/squid/squid.conf
RUN echo "redirect_program /usr/bin/squidGuard -c /etc/squidguard/squidGuard.conf" >> /etc/squid/squid.conf

RUN rm /etc/squidguard/squidGuard.conf
ADD sample-config-blacklist /sample-config-blacklist
ADD sample-config-simple /sample-config-simple
RUN mkdir /custom-config

ADD entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

ADD startSquidGuard /startSquidGuard
RUN chmod a+x /startSquidGuard

EXPOSE 3128 80
VOLUME ["/var/log/squid"]
VOLUME ["/custom-config"]

CMD ["/startSquidGuard"]
