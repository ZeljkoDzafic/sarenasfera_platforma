# Nginx SSL configuration for platforma.sarenasfera.com
# This file is for reference - actual SSL certs are managed by Let's Encrypt/Certbot

# To generate SSL certificates:
# docker run --rm -v ./certs:/etc/letsencrypt certbot/certbot certonly \
#   --standalone \
#   -d platforma.sarenasfera.com \
#   -d www.platforma.sarenasfera.com \
#   --email admin@sarenasfera.com \
#   --agree-tos \
#   --no-eff-email

# For auto-renewal, add to crontab:
# 0 2 * * * docker run --rm -v ./certs:/etc/letsencrypt certbot/certbot renew --quiet
