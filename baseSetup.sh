#!/bin/bash

# Функция для настройки iptables
setup_iptables() {
    echo "Загружается и выполняется скрипт для настройки iptables..."
    bash <(curl -s https://raw.githubusercontent.com/YAMISHKA02/NodeScripts/refs/heads/main/iptable.sh)
    echo "Настройка iptables завершена."
}

# Функция для установки Fail2ban
install_fail2ban() {
    echo "Загружается и выполняется скрипт для установки Fail2ban..."
    bash <(curl -s https://raw.githubusercontent.com/YAMISHKA02/NodeScripts/refs/heads/main/file2ban.sh)
    echo "Установка Fail2ban завершена."
}

install_docker() {
    echo "Загружаем Docker"
    bash <(curl -s https://raw.githubusercontent.com/YAMISHKA02/NodeScripts/refs/heads/main/docker.sh)
    echo "Установка Docker завершена."
}

install_packs() {
    bash <(curl -s https://raw.githubusercontent.com/YAMISHKA02/NodeScripts/refs/heads/main/packs.sh)
    echo "Установка зависимостей завершена."
}
# Функция для отображения меню
show_menu() {
    echo "Выберите действие:"
    echo "1. Настройка iptables"
    echo "2. Установка Fail2ban"
    echo "3. Установка Docker"
    echo "4. Установка зависимостей"
    echo "0. Выход"
}

# Функция для обработки выбора пользователя
handle_choice() {
    case "$1" in
        1) setup_iptables ;;
        2) install_fail2ban ;;
        3) install_docker ;;
        4) install_packs ;;
        0) echo "Выход."; exit 0 ;;
        *) echo "Неверный выбор. Попробуйте снова." ;;
    esac
}

while true; do
    show_menu
    read -p "Ваш выбор: " action
    handle_choice "$action"  # Используем переменную action
done
