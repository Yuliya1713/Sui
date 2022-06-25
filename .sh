#!/bin/bash
echo "-----------------------------------------------------------------------------"
curl -s https://raw.githubusercontent.com/razumv/helpers/main/doubletop.sh | bash
echo "-----------------------------------------------------------------------------"

echo "-----------------------------------------------------------------------------"
echo "Устанавливаем софт"
echo "-----------------------------------------------------------------------------"
sudo apt update && sudo apt install curl -y &>/dev/null
apt-get update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y --no-install-recommends tzdata git ca-certificates libclang-dev cmake &>/dev/null
curl -s https://raw.githubusercontent.com/razumv/helpers/main/tools/install_ufw.sh | bash &>/dev/null
curl -s https://raw.githubusercontent.com/razumv/helpers/main/tools/install_rust.sh | bash &>/dev/null
source $HOME/.cargo/env
source $HOME/.profile
source $HOME/.bashrc
sleep 1
echo "Весь необходимый софт установлен"
echo "-----------------------------------------------------------------------------"
git clone https://github.com/MystenLabs/sui.git &>/dev/null
cd sui
git remote add upstream https://github.com/MystenLabs/sui
git fetch upstream &>/dev/null
git checkout -B devnet --track upstream/devnet &>/dev/null
mkdir -p /var/sui/db
cp crates/sui-config/data/fullnode-template.yaml /var/sui/fullnode.yaml
wget -O /var/sui/genesis.blob https://github.com/MystenLabs/sui-genesis/raw/main/devnet/genesis.blob &>/dev/null
sed -i.bak "s/db-path:.*/db-path: \"\/var\/sui\/db\"/ ; s/genesis-file-location:.*/genesis-file-location: \"\/var\/sui\/genesis.blob\"/" /var/sui/fullnode.yaml
echo "Репозиторий успешно склонирован, начинаем билд"
echo "-----------------------------------------------------------------------------"
cargo build --release -p sui-node 
mv ~/sui/target/release/sui-node /usr/local/bin/
echo "Билд закончен, переходим к инициализации ноды"
echo "-----------------------------------------------------------------------------"
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
sudo systemctl restart systemd-journald

sudo tee <<EOF >/dev/null /etc/systemd/system/sui.service
[Unit]
  Description=SUI Node
  After=network-online.target
[Service]
  User=$USER
  ExecStart=/usr/local/bin/sui-node --config-path /var/sui/fullnode.yaml
  Restart=on-failure
  RestartSec=3
  LimitNOFILE=4096
[Install]
  WantedBy=multi-user.target
EOF

sudo systemctl enable sui &>/dev/null
sudo systemctl daemon-reload
sudo systemctl restart sui

echo "Fullnode sui успешно установлена"
echo "-----------------------------------------------------------------------------"
