lokal_ip=$(hostname -I | awk '{print $1}')
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

echo -e "${YELLOW}Apakah Anda ingin melanjutkan instalasi GenieACS? (y/n): ${RESET}"
read -p "> " konfirmasi
if [[ ! "$konfirmasi" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Instalasi dibatalkan.${RESET}"
    exit 1
fi

echo -e "${YELLOW}Memulai instalasi GenieACS...${RESET}"
echo "Menginstal Node.js..."
curl -sL https://deb.nodesource.com/setup_14.x -o nodesource_setup.sh
bash nodesource_setup.sh
apt install -y nodejs
node -v

echo "Menginstal MongoDB..."
curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.4.list
apt update
apt install -y mongodb-org
systemctl start mongod.service
systemctl enable mongod

mongo --eval 'db.runCommand({ connectionStatus: 1 })'

echo "Menginstal GenieACS..."
npm install -g --unsafe-perm genieacs@1.2.7
useradd --system --no-create-home --user-group genieacs
mkdir -p /opt/genieacs/ext
chown genieacs:genieacs /opt/genieacs/ext

echo "Membuat file konfigurasi GenieACS..."
cat <<EOF > /opt/genieacs/genieacs.env
GENIEACS_CWMP_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-cwmp-access.log
GENIEACS_NBI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-nbi-access.log
GENIEACS_FS_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-fs-access.log
GENIEACS_UI_ACCESS_LOG_FILE=/var/log/genieacs/genieacs-ui-access.log
GENIEACS_DEBUG_FILE=/var/log/genieacs/genieacs-debug.yaml
GENIEACS_EXT_DIR=/opt/genieacs/ext
GENIEACS_UI_JWT_SECRET=secret
EOF
chown genieacs:genieacs /opt/genieacs/genieacs.env
chmod 600 /opt/genieacs/genieacs.env
mkdir -p /var/log/genieacs
chown genieacs:genieacs /var/log/genieacs

echo "Membuat file unit systemd untuk GenieACS..."
cat <<EOF > /etc/systemd/system/genieacs-cwmp.service
[Unit]
Description=GenieACS CWMP
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-cwmp

[Install]
WantedBy=default.target
EOF

cat <<EOF > /etc/systemd/system/genieacs-nbi.service
[Unit]
Description=GenieACS NBI
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-nbi

[Install]
WantedBy=default.target
EOF

cat <<EOF > /etc/systemd/system/genieacs-fs.service
[Unit]
Description=GenieACS FS
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-fs

[Install]
WantedBy=default.target
EOF

cat <<EOF > /etc/systemd/system/genieacs-ui.service
[Unit]
Description=GenieACS UI
After=network.target

[Service]
User=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-ui

[Install]
WantedBy=default.target
EOF

cat <<EOF > /etc/logrotate.d/genieacs
/var/log/genieacs/*.log /var/log/genieacs/*.yaml {
    daily
    rotate 30
    compress
    delaycompress
    dateext
}
EOF

echo "Mengaktifkan dan memulai layanan GenieACS..."
systemctl daemon-reload
systemctl enable genieacs-cwmp
systemctl start genieacs-cwmp
systemctl enable genieacs-nbi
systemctl start genieacs-nbi
systemctl enable genieacs-fs
systemctl start genieacs-fs
systemctl enable genieacs-ui
systemctl start genieacs-ui

echo -e "${GREEN}Instalasi GenieACS selesai!${RESET}"
echo -e "${GREEN}Buka http://$lokal_ip:3000 di browser untuk akses UI GenieACS.${RESET}"
echo -e "${GREEN}------------------------------${RESET}"
echo -e "${GREEN}Terima kasih telah menggunakan script ini!${RESET}"
echo -e "${GREEN}Follow Instagram: @nandaaa_79${RESET}"
echo -e "${GREEN}------------------------------${RESET}"
