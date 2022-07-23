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
rm -rf /var/sui/db /var/sui/genesis.blob $HOME/sui
mkdir -p $HOME/.sui
git clone https://github.com/kuraassh/sui.git &>/dev/null
cd sui
git remote add upstream https://github.com/MystenLabs/sui
git fetch upstream &>/dev/null
git checkout --track upstream/devnet &>/dev/null
echo "Репозиторий успешно склонирован, начинаем билд"
echo "-----------------------------------------------------------------------------"
cargo build --release
mv $HOME/sui/target/release/{sui,sui-node,sui-faucet} /usr/bin/
wget -qO $HOME/.sui/genesis.blob https://github.com/MystenLabs/sui-genesis/raw/main/devnet/genesis.blob
cp $HOME/sui/crates/sui-config/data/fullnode-template.yaml \
$HOME/.sui/fullnode.yaml
sed -i -e "s%db-path:.*%db-path: \"$HOME/.sui/db\"%; "\
"s%metrics-address:.*%metrics-address: \"0.0.0.0:9184\"%; "\
"s%json-rpc-address:.*%json-rpc-address: \"0.0.0.0:9000\"%; "\
"s%genesis-file-location:.*%genesis-file-location: \"$HOME/.sui/genesis.blob\"%; " $HOME/.sui/fullnode.yaml
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
  ExecStart=`which sui-node` --config-path $HOME/.sui/fullnode.yaml
  Restart=on-failure
  RestartSec=3
  LimitNOFILE=65535
[Install]
  WantedBy=multi-user.target
EOF

sudo systemctl enable sui &>/dev/null
sudo systemctl daemon-reload
sudo systemctl restart sui

echo "Fullnode sui успешно установлена"
echo "-----------------------------------------------------------------------------"
