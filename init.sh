#!/bin/bash

set -e
set -x
echo "$@"

# Check if all env parameters exist
[ -z "$ACCESS_ALLOWED_CIDR" ] && echo "ACCESS_ALLOWED_CIDR env variable not defined! Exiting..." && exit 1
[ -z "$BASE_DOMAIN" ] && echo "BASE_DOMAIN env variable not defined! Exiting..." && exit 1
[ -z "$DOMAIN_EXTENSION" ] && echo "DOMAIN_EXTENSION env variable not defined! Exiting..." && exit 1
[ -z "$GOOGLE_LDAP_PASSWORD" ] && echo "GOOGLE_LDAP_PASSWORD env variable not defined! Exiting..." && exit 1
[ -z "$GOOGLE_LDAP_USERNAME" ] && echo "GOOGLE_LDAP_USERNAME env variable not defined! Exiting..." && exit 1

# replace all those env params in the file
sed -i "s|ACCESS_ALLOWED_CIDR|$ACCESS_ALLOWED_CIDR|g" /etc/freeradius/clients.conf
sed -i "s|SHARED_SECRET|$SHARED_SECRET|g" /etc/freeradius/clients.conf

sed -i "s|BASE_DOMAIN|$BASE_DOMAIN|g" /etc/freeradius/proxy.conf
sed -i "s|DOMAIN_EXTENSION|$DOMAIN_EXTENSION|g" /etc/freeradius/proxy.conf

sed -i "s|GOOGLE_LDAP_PASSWORD|$GOOGLE_LDAP_PASSWORD|g" /etc/freeradius/mods-available/ldap
sed -i "s|GOOGLE_LDAP_USERNAME|$GOOGLE_LDAP_USERNAME|g" /etc/freeradius/mods-available/ldap

# add support to second level like: .com.br, .com.ar
sed -i "s|BASE_DOMAIN|$BASE_DOMAIN|g" /etc/freeradius/mods-available/ldap
if [[ ${DOMAIN_EXTENSION} =~ [.] ]]; then
    DOMAIN_EXTENSION=$( echo $DOMAIN_EXTENSION | awk -F'.' '{print $1",dc="$2}' )
fi
sed -i "s|DOMAIN_EXTENSION|$DOMAIN_EXTENSION|g" /etc/freeradius/mods-available/ldap

# Handle the certs
cp /certs/* /etc/freeradius/certs/
chown freerad:freerad /etc/freeradius/certs/*
chmod 640 /etc/freeradius/certs/*


/docker-entrypoint.sh "$@"
