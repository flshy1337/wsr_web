#!/bin/bash
yes | ufw enable
systemctl enable --force ufw
ufw allow 8080
ufw allow 80
ufw allow 443
ufw allow http
ufw allow https
ufw allow ssh
ufw reload
/home/azadmin/web-53 &
