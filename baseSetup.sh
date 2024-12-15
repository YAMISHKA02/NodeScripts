#!/bin/bash

# Функция для настройки iptables
setup_iptables() {
    echo "Загружается и выполняется скрипт для настройки iptables..."
    bash <(curl -H "Authorization: token " \
     -s https://raw.githubusercontent.com/YAMISHKA02/NodeGoods/refs/heads/main/NewServer/iptables.sh)
    echo "Настройка iptables завершена."
}

# Функция для установки Fail2ban
install_fail2ban() {
    echo "Загружается и выполняется скрипт для установки Fail2ban..."
    bash <(curl -H "Authorization: token " \
     -s https://raw.githubusercontent.com/YAMISHKA02/NodeGoods/refs/heads/main/NewServer/file2ban.sh)
    echo "Установка Fail2ban завершена."
}

install_docker() {
    echo "Загружаем Docker"
    bash <(curl -H "Authorization: token " \
     -s https://raw.githubusercontent.com/YAMISHKA02/NodeGoods/refs/heads/main/NewServer/docker.sh)
    echo "Установка Docker завершена."
}


# Функция для обработки выбора пользователя
handle_choice() {
    case "$1" in
        1) setup_iptables ;;
        2) install_fail2ban ;;
        3) install_docker ;;
        #4) clear_memory ;; 
        #9) node_list_start ;;               
        0) echo "Выход."; exit 0 ;;
        *) echo "Неверный выбор. Попробуйте снова." ;;
    esac
}

while true; do
    show_menu
    read -p "Ваш выбор: " action
    handle_choice "$action"  # Используем переменную action
done
