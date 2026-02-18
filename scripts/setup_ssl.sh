#!/bin/bash
set -euo pipefail

CERT="/etc/pki/tls/certs/linux-reporting.crt"
KEY="/etc/pki/tls/private/linux-reporting.key"
SSL_CONF="/etc/httpd/conf.d/ssl.conf"

dnf install -y mod_ssl openssl

# Create cert/key if missing
if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
  openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout "$KEY" \
    -out "$CERT" \
    -subj "/C=NA/ST=NA/L=NA/O=linux-reporting/OU=lab/CN=172.16.10.10"
fi

# Point Apache to our cert/key
# Replace existing SSLCertificateFile / SSLCertificateKeyFile lines
sed -i \
  -e "s|^SSLCertificateFile .*|SSLCertificateFile $CERT|g" \
  -e "s|^SSLCertificateKeyFile .*|SSLCertificateKeyFile $KEY|g" \
  "$SSL_CONF"

systemctl enable --now httpd
systemctl restart httpd

echo "OK: SSL configured and httpd restarted"
