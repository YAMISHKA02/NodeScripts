#!/bin/bash
# Скрипт управления Fail2ban для защиты SSH


JAIL_LOCAL="/etc/fail2ban/jail.local"

install_fail2ban() {
    # Установка и настройка логирования, если отсутствует
    bash <(curl -s https://raw.githubusercontent.com/YAMISHKA02/NodeScripts/refs/heads/main/auth_logs.sh)

    echo "🔍 Проверка наличия Fail2ban..."
    if dpkg -l | grep -q fail2ban; then
        echo "⚠️ Fail2ban уже установлен. Пропускаем установку."
    else
        echo "🛠️ Установка Fail2ban..."
        sudo apt update
        sudo apt install -y fail2ban
        echo "✅ Fail2ban успешно установлен."
    fi
}



# Функция для создания конфигурационного файла джейла SSH
create_jail_local() {
    echo -e "\n📁 Создание конфигурационного файла $JAIL_LOCAL..."
    cat <<EOL > $JAIL_LOCAL
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
findtime = 6000
bantime = -1
EOL

    echo "✅ Конфигурация для sshd создана."
}

# Функция перезапуска Fail2ban
restart_fail2ban() {
    echo -e "\n🔄 Перезапуск Fail2ban..."
    systemctl restart fail2ban
    if systemctl is-active --quiet fail2ban; then
        echo "✅ Fail2ban успешно запущен."
    else
        echo "❌ Ошибка: Fail2ban не удалось запустить. Проверьте конфигурацию."
        exit 1
    fi
}

# Функция просмотра списка ignoreip
view_ignore_ip() {
    echo "📋 Текущий список исключений (ignoreip):"
    grep -oP '(?<=ignoreip = ).*' "$JAIL_LOCAL"
}

# Функция добавления IP в ignoreip
add_ignore_ip() {
    local ip
    view_ignore_ip
    read -rp "Введите IP-адрес для добавления в исключения: " ip

    if grep -q "ignoreip" "$JAIL_LOCAL"; then
        if grep -q "ignoreip.*$ip" "$JAIL_LOCAL"; then
            echo "⚠️ IP-адрес $ip уже есть в списке исключений."
        else
            sed -i "/ignoreip/c\ignoreip = $(grep -oP '(?<=ignoreip = ).*' $JAIL_LOCAL) $ip" "$JAIL_LOCAL"
            echo "✅ IP-адрес $ip добавлен в список исключений."
        fi
    else
        echo "ignoreip = $ip" >> "$JAIL_LOCAL"
        echo "✅ Добавлено поле ignoreip с IP-адресом $ip."
    fi
    restart_fail2ban
}

# Функция удаления IP из ignoreip
remove_ignore_ip() {
    local ip
    view_ignore_ip
    read -rp "Введите IP-адрес для удаления из исключений: " ip
    if grep -q "ignoreip.*$ip" "$JAIL_LOCAL"; then
        sed -i "/ignoreip/c\ignoreip = $(grep -oP '(?<=ignoreip = ).*' $JAIL_LOCAL | sed "s/\b$ip\b//g" | xargs)" "$JAIL_LOCAL"
        echo "✅ IP-адрес $ip удален из списка исключений."
        restart_fail2ban
    else
        echo "⚠️ IP-адрес $ip не найден в списке исключений."
    fi
}

# Функция проверки статуса джейла sshd
check_jail_status() {
    echo -e "\nℹ️ Проверка статуса jail sshd..."
    fail2ban-client status sshd
}

# Функция изменения параметров конфигурации
change_settings() {

    echo -e "\n⚙️ Изменение настроек джейла sshd:"

    # Запрос значений у пользователя с указанием значений по умолчанию
    read -rp "Введите количество попыток перед блокировкой (maxretry) [3]: " maxretry
    read -rp "Введите время отслеживания (findtime, в секундах) [3600]: " findtime
    read -rp "Введите время блокировки (bantime, по умолчанию -1 для постоянной блокировки): " bantime

    # Применяем значения по умолчанию, если пользователь оставил поле пустым
    maxretry="${maxretry:-3}"
    findtime="${findtime:-3600}"
    bantime="${bantime:--1}"  # Постоянная блокировка по умолчанию

    # Применение изменений в jail.local
    sed -i "/maxretry/c\maxretry = $maxretry" "$JAIL_LOCAL"
    sed -i "/findtime/c\findtime = $findtime" "$JAIL_LOCAL"
    sed -i "/bantime/c\bantime = $bantime" "$JAIL_LOCAL"

    echo -e "\n✅ Новые параметры сохранены в $JAIL_LOCAL:"
    echo "maxretry = $maxretry, findtime = $findtime, bantime = $bantime"

    restart_fail2ban
}

# Функция удаления IP из заблокированных
unban_ip() {
    local ip
    read -rp "Введите IP-адрес для разблокировки: " ip

    echo "🔍 Проверка и разблокировка IP $ip..."
    if fail2ban-client status sshd | grep -q "$ip"; then
        fail2ban-client unban "$ip"
        echo "✅ IP-адрес $ip успешно разблокирован."
    else
        echo "⚠️ IP-адрес $ip не найден в списке заблокированных."
    fi
}

# Функция меню
show_menu() {
    echo -e "\n==============================="
    echo "    Выберите действие:"
    echo "==============================="
    echo "1. 🛠 Установка Fail2ban"
    echo "2. ⚙️ Изменение настроек блокировки"
    echo "3. 🔓 Разблокировка IP адреса"
    echo "4. ➕ Добавить IP в список исключения"
    echo "5. ➖ Удалить IP из списка исключений"
    echo "6. 📋 Просмотр списка исключений"
    echo "8. 📊 Проверка статуса jail sshd"
    echo "9. 🔍 Просмотр успешных попыток входа"
    echo "0. 🚪 Выход"
    echo "==============================="
    read -rp "Ваш выбор: " choice
    echo ""
    case $choice in
        1)
            install_fail2ban
            create_jail_local
            restart_fail2ban
            ;;
        2)
            change_settings
            ;;
        3) 
            unban_ip
            ;;
        4)
            add_ignore_ip
            ;;
        5)
            remove_ignore_ip
            ;;
        6)
            view_ignore_ip
            ;;
        8)
            check_jail_status
            ;;
        9) 
            sudo grep "Accepted password" /var/log/auth.log
            ;;
        0)
            echo "👋 Выход..."
            exit 0
            ;;
        *)
            echo "❌ Неверный выбор, попробуйте снова."
            ;;
    esac
}

# Главная функция
main() {
    while true; do
        show_menu
    done
}

# Запуск главной функции
main
