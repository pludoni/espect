Espect is a tiny web service that accepts e-mails, runs them through SpamAssassin and ClamAV and returns JSON. The original repo has been merged into [Postal](https://github.com/atech/postal).

Espect provides a tiny ruby server in front of a SpamAssassin and ClamAV to easily and GDPR conform scan everything locally.

## Client Usage

```
curl localhost:8898/inspect -d "$(base64 message.eml)"

{"spam_score":2.2,
 "spam_details":[{"code":"URIBL_BLOCKED","score":0.0,"description":"ADMINISTRATOR NOTICE: The query to URIBL was blocked.  See http://wiki.apache.org/spamassassin/DnsBlocklists#dnsbl-block for more information. [URIs: phpclasses.org]"},{"code":"NO_RELAYS","score":-0.0,"description":"Informational: message was not relayed via SMTP"},{"code":"HTML_MESSAGE","score":0.0,"description":"BODY: HTML included in message"},{"code":"TVD_FW_GRAPHIC_NAME_LONG","score":0.6,"description":"BODY: Long image attachment name"},{"code":"HTML_IMAGE_ONLY_12","score":1.6,"description":"BODY: HTML: images with 800-1200 bytes of words"},{"code":"NO_RECEIVED","score":-0.0,"description":"Informational: message has no Received headers"}],
"threat":false,
"threat_message":"No threats found"
}
```

## Installation

### Scanner App

```
useradd -s /bin/bash scanner
git clone https://github.com/pludoni/espect.git /opt/espect
chown scanner /opt/espect -R
gem i bundler -v 1.17.3
su - scanner
cd /opt/espect
bundle --path ./vendor/gems
cp config.yml.example config.yml
```

Adjust config.yml if necessary

### example systemd startup

```
#/etc/systemd/system/puma.service
[Unit]
Description=Puma HTTP Server
After=network.target
[Service]
Type=simple
User=scanner
WorkingDirectory=/opt/espect
ExecStart=/usr/local/bin/bundle exec puma -C puma.rb
Restart=always
[Install]
WantedBy=multi-user.target
```

```
systemctl daemon-reload
systemctl enable puma.service
systemctl start puma.service
```


### Clamav

```
apt install clamav-daemon clamav-freshclam libclamunrar7 unzip
wget -O /var/lib/clamav/main.cvd http://database.clamav.net/main.cvd
wget -O /var/lib/clamav/daily.cvd http://database.clamav.net/daily.cvd
wget -O /var/lib/clamav/bytecode.cvd http://database.clamav.net/bytecode.cvd
chown clamav:clamav /var/lib/clamav/*.cvd
sed -i 's/^Foreground .*$/Foreground true/g' /etc/clamav/clamd.conf
echo "TCPSocket 3310" >> /etc/clamav/clamd.conf
sed -i 's/^Foreground .*$/Foreground true/g' /etc/clamav/freshclam.conf
freshclam
service clamav-freshclam status
```

### SpamAssassin

```
apt install spamassassin spamc pyzor razor libmail-dkim-perl libnet-ident-perl libsocket-getaddrinfo-perl
mkdir -p /etc/spamassassin/sa-update-keys
chmod 700 /etc/spamassassin/sa-update-keys
chown debian-spamd:debian-spamd /etc/spamassassin/sa-update-keys
mkdir -p /var/lib/spamassassin/.pyzor
chmod 700 /var/lib/spamassassin/.pyzor
echo "public.pyzor.org:24441" > /var/lib/spamassassin/.pyzor/servers
chmod 600 /var/lib/spamassassin/.pyzor/servers
chown -R debian-spamd:debian-spamd /var/lib/spamassassin/.pyzor
systemctl enable spamassassin.service
systemctl start spamassassin.service
```

### Caddy (https front)


```
# /etc/caddy/Caddyfile
scanner.myhost.com {
  proxy / localhost:8898 {
    transparent
  }
  limits {
    body 20MB
  }
  timeouts 30s
}
```

```
# /etc/systemd/system/caddy.service
[Unit]
Description=Caddy HTTP/2 web server
Documentation=https://caddyserver.com/docs
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service
[Service]
Restart=on-abnormal
Environment=CADDYPATH=/etc/ssl/caddy
ExecStart=/usr/local/bin/caddy -log stdout -agree=true -conf=/etc/caddy/Caddyfile -root=/var/tmp
ExecReload=/bin/kill -USR1 $MAINPID
KillMode=mixed
KillSignal=SIGQUIT
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
PrivateDevices=false
ProtectHome=true
ProtectSystem=full
ReadWritePaths=/etc/ssl/caddy
ReadWriteDirectories=/etc/ssl/caddy
[Install]
WantedBy=multi-user.target
```


```bash
wget https://github.com/caddyserver/caddy/releases/download/v1.0.3/caddy_v1.0.3_linux_amd64.tar.gz
tar xf caddy_v1.0.3_linux_amd64.tar.gz
mv caddy /usr/local/bin/caddy

mkdir /etc/caddy
touch /etc/caddy/Caddyfile
sudo mkdir /etc/ssl/caddy
sudo chown -R root:www-data /etc/ssl/caddy
sudo chmod 0770 /etc/ssl/caddy

sudo systemctl daemon-reload
sudo systemctl start caddy.service
```
