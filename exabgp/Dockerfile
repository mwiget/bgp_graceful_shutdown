FROM alpine:3.6

RUN apk add --no-cache tini ethtool py2-pip && pip install exabgp

EXPOSE 179

WORKDIR /etc/exabgp

COPY exabgp.conf launch.sh /etc/exabgp/
RUN chmod a+rx *.sh

ENTRYPOINT ["/sbin/tini", "./launch.sh"]
