#!/bin/bash
echo "-----------------------------------------------------------------------------"
curl -s https://raw.githubusercontent.com/razumv/helpers/main/doubletop.sh | bash
echo "-----------------------------------------------------------------------------"

echo "-----------------------------------------------------------------------------"
echo "Выполняем обновление"
echo "-----------------------------------------------------------------------------"
sudo systemctl stop sui
rm -rf $HOME/.sui/db
wget -qO $HOME/.sui/genesis.blob https://github.com/MystenLabs/sui-genesis/raw/main/devnet/genesis.blob
cd $HOME/sui
git remote add upstream https://github.com/MystenLabs/sui
git fetch upstream
git stash
git checkout -B devnet --track upstream/devnet
echo "-----------------------------------------------------------------------------"
echo "Устанавливаем обновление"
echo "-----------------------------------------------------------------------------"
cargo build --release
sudo mv $HOME/sui/target/release/{sui,sui-node,sui-faucet} /usr/bin/
sudo systemctl restart sui
echo "-----------------------------------------------------------------------------"
echo "Обновление завершено"
echo "-----------------------------------------------------------------------------"
