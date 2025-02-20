#!/bin/bash

CONFIG_FILE="/etc/proxychains.conf"

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

# Функция для запроса данных прокси
prompt_proxy_details() {
    read -p "IP-адрес: " PROXY_IP
    read -p "Порт: " PROXY_PORT
    read -p "Логин: " PROXY_USER
    read -p "Пароль: " PROXY_PASS
    echo "socks5 ${PROXY_IP} ${PROXY_PORT} ${PROXY_USER} ${PROXY_PASS}"
}

# Функция для комментария строк с socks4
comment_socks4() {
    sudo sed -i '/^socks4 / s/^/# /' "$CONFIG_FILE"
}

# Создаём резервную копию файла перед изменениями
sudo cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

# Комментируем socks4
comment_socks4

# Удаляем старую запись socks5 (если есть)
sudo sed -i '/^socks5 /d' "$CONFIG_FILE"

# Запрашиваем новый прокси
proxy_line=$(prompt_proxy_details)

# Добавляем новую запись
echo "$proxy_line" | sudo tee -a "$CONFIG_FILE" >/dev/null

echo "Прокси успешно обновлён."
