# syntax=docker/dockerfile:1.4-labs
FROM nginx:latest

RUN apt update
RUN apt install -y cron
RUN apt install -y python3 python3.11-venv
RUN python3 -m venv /opt/certbot/
RUN /opt/certbot/bin/pip install --upgrade pip
RUN /opt/certbot/bin/pip install certbot certbot-nginx
RUN ln -s /opt/certbot/bin/certbot /usr/bin/certbot

COPY <<-EOT /docker-entrypoint.d/issue_certs.sh
  #!/bin/sh
  if [ ! -d /etc/letsencrypt/live ]; then
    echo "no certificates were found";
    echo "issuing certs for \${DOMAINS:?variable not set}";
    certbot certonly -v --standalone --agree-tos -d \${DOMAINS:?variable not set} -m \${EMAIL:?variable not set}
    #yes 1 | certbot reconfigure -a nginx -i nginx
  fi;
EOT

RUN chmod +x /docker-entrypoint.d/issue_certs.sh
COPY ./index.html /usr/share/nginx/html/
COPY ./favicon.png /usr/share/nginx/html/favicon.ico
RUN chmod 644 /usr/share/nginx/html/index.html
RUN echo "0 0,12 * * * root /opt/certbot/bin/python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew --nginx -q" | tee -a /etc/crontab > /dev/null
