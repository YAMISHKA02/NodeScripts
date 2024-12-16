#!/bin/bash

# Сообщение о начале установки
echo "Устанавливаем зависимости..."
sleep 3

# Обновление списка пакетов и системы
sudo apt-get update -y && sudo apt-get upgrade -y

# Установка необходимых пакетов
sudo apt-get install -y make build-essential unzip lz4 gcc git jq screen nano

echo "Установка зависимостей завершена."
