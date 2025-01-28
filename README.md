# FreeRadius - Google Secure LDAP 

Based on the work of:

- The [FreeRADIUS](https://github.com/FreeRADIUS/freeradius-server) maintainers
- [hacor's](https://github.com/hacor) [unifi-freeradius-ldap](https://github.com/hacor/unifi-freeradius-ldap) project

## Generate your own certificates

You can use OpenSSL to generate your own certificates. The following steps will guide you through the process.

1. Generate the CA key

    ```bash
    openssl genrsa -out ca.key 4096
    ```

2. Generate the CA Certificate - Remember to answer the questions

    ```bash
    # CA cert valid for 10 years
    openssl req -x509 -new -nodes -key ca.key -sha256 -days 3650 -out ca.pem
    ```

3. Generate the server key

    ```bash
    openssl genrsa -out server.key 4096
    ```

4. Create a signing request

    ```bash
    openssl req -new -key server.key -out server.csr
    ```

5. Sign the certificate with the CA

    ```bash
    openssl x509 -req -in server.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out server.crt -days 3650 -sha256
    ```

6. Convert to all needed formats

    ```bash
    openssl pkcs12 -export -in server.crt -inkey server.key -certfile ca.pem -out server.p12 -name "My EAP Server"
    openssl pkcs12 -in server.p12 -out server.pem -nodes
    ```

7. Generate a dhparam file

    ```bash
    openssl dhparam -out dh 4096
    ```
