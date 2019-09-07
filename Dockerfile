FROM alpine:3.10

MAINTAINER Andrey Mamaev <asda@asda.ru>

RUN apk --update add \
	mariadb-client \
	freeradius \
	freeradius-mysql \
    rm -rf /var/cache/apk/*

ENV RADIUS_DB_PWD=radpass
ENV CLIENT_NET="0.0.0.0/0"
ENV CLIENT_SECRET=testing123

RUN  ln -s /etc/freeradius/3.0/mods-available/sql /etc/freeradius/3.0/mods-enabled
COPY init.sh /	

EXPOSE 1812 1813

ENTRYPOINT ["/init.sh"]
