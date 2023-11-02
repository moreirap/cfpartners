#!/bin/bash

openssl req -subj '/CN=myclientcertificate/O=MyCompany, Inc./ST=CA/C=US' -new -newkey rsa:4096 -sha256 -days 730 -nodes -x509 -keyout client.key -out client.crt

openssl pkcs12 -export -password pass:"Pa55w0rd123" -out client.pfx -inkey client.key -in client.crt
