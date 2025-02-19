#!/bin/bash

# Цвета
ORANGE='\e[38;5;214m'
RESET='\e[0m'

show() {
    echo -e "\033[33m$1\033[0m"
}

# Логотип
show " ____   _   _  ___  ____   _   _  _  __    _    "
show "/ ___| | | | ||_ _|/ ___| | | | || |/ /   / \   "
show "\___ \ | |_| | | | \___ \ | |_| || ' /   / _ \  "
show " ___) ||  _  | | |  ___) ||  _  || . \  / ___ \ "
show "|____/ |_| |_||___||____/ |_| |_||_|\_\/_/   \_\ "
show "  ____  ____ __   __ ____  _____  ___           "
show " / ___||  _ \\ \ / /|  _ \|_   _|/ _ \          "
show "| |    | |_) |\ V / | |_) | | | | | | |         "
show "| |___ |  _ <  | |  |  __/  | | | |_| |         "
show " \____||_| \_\ |_|  |_|     |_|  \___/          "
show " _   _   ___   ____   _____  ____               "
show "| \ | | / _ \ |  _ \ | ____|/ ___|              "
show "|  \| || | | || | | ||  _|  \___ \              "
show "| |\  || |_| || |_| || |___  ___) |             "
show "|_| \_| \___/ |____/ |_____||____/              "

sleep 3

function print_msg() {
    echo -e "${ORANGE}$1${RESET}"
}

print_msg "Обновляем пакеты..."
sudo apt update -y

print_msg "Устанавливаем curl..."
sudo apt install curl -y

print_msg "Обновляем систему..."
sudo apt upgrade -y

print_msg "Устанавливаем необходимые пакеты..."
sudo apt install -y build-essential pkg-config libssl-dev git-all protobuf-compiler cargo screen unzip

print_msg "Устанавливаем Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
rustup update

print_msg "Удаляем системный protobuf-compiler..."
sudo apt remove -y protobuf-compiler

print_msg "Скачиваем и устанавливаем protobuf-compiler 25.2..."
curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v25.2/protoc-25.2-linux-x86_64.zip
unzip protoc-25.2-linux-x86_64.zip -d "$HOME/.local"
export PATH="$HOME/.local/bin:$PATH"

print_msg "Проверяем версию protoc..."
protoc --version

print_msg "Запускаем screen-сессию nexus..."
screen -dmS nexus

print_msg "✅ Установка завершена! ✅"
print_msg "\nЗапустите команду: ${ORANGE}screen -r nexus${RESET}"
print_msg "\n🚀 Подписывайтесь на: ${ORANGE}https://t.me/shishka_crypto${RESET}\n"
