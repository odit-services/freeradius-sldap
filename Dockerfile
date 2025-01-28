ARG from=debian:bookworm
FROM ${from} AS build

ARG DEBIAN_FRONTEND=noninteractive

#
#  Install build tools
#
RUN apt-get update
RUN apt-get install -y devscripts equivs git quilt gcc

#
#  Create build directory
#
RUN mkdir -p /usr/local/src/repositories
WORKDIR /usr/local/src/repositories

#
#  Shallow clone the FreeRADIUS source
#
ARG source=https://github.com/FreeRADIUS/freeradius-server.git
ARG release=v3.0.x

RUN git clone --depth 1 --single-branch --branch ${release} ${source}
WORKDIR freeradius-server

#
#  Install build dependencies
#
RUN git checkout ${release}; \
    if [ -e ./debian/control.in ]; then \
        debian/rules debian/control; \
    fi; \
    echo 'y' | mk-build-deps -irt'apt-get -yV' debian/control

#
#  Build the server
#
RUN make -j2 deb

#
#  Clean environment and run the server
#
FROM ${from} AS base
COPY --from=build /usr/local/src/repositories/*.deb /tmp/

ARG freerad_uid=101
ARG freerad_gid=101

RUN groupadd -g ${freerad_gid} -r freerad \
    && useradd -u ${freerad_uid} -g freerad -r -M -d /etc/freeradius -s /usr/sbin/nologin freerad \
    && apt-get update \
    && apt-get install -y /tmp/*.deb \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/* /tmp/*.deb \
    \
    && ln -s /etc/freeradius /etc/raddb

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh


ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["freeradius"]

FROM base AS production

LABEL org.opencontainers.image.source="https://github.com/odit.services/freeradius-sldap"
LABEL org.opencontainers.image.description="FreeRADIUS preconfigured to work with Google's secure ldap as the authentication backend"
LABEL org.opencontainers.image.licenses="GPL-2.0"

COPY configs/clients.conf /etc/freeradius/clients.conf
COPY configs/default /etc/freeradius/sites-available/default
COPY configs/inner-tunnel /etc/freeradius/sites-available/inner-tunnel
COPY configs/ldap /etc/freeradius/mods-available/ldap
COPY configs/eap /etc/freeradius/mods-enabled/eap
COPY configs/proxy.conf /etc/freeradius/proxy.conf
COPY init.sh /usr/local/bin
RUN chmod +x /usr/local/bin/init.sh && \
    ln -s /etc/freeradius/mods-available/ldap /etc/freeradius/mods-enabled/ldap

EXPOSE 1812/udp 1813/udp
ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["freeradius"]