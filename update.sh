#!/bin/bash

# log dosyasının konumu
LOG_FILE="/var/log/system_update.log"

# renki cıktılar 
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
NC="\033[0m" 

# dagitim tespiti yapma os-release dosyasından 
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# guncelleme fonksiyonu
update_system() {
    local distro=$(detect_distro)
    case "$distro" in
        ubuntu|debian)
            echo -e "${YELLOW}[INFO] Debian/Ubuntu tabanlı sistem tespit edildi.${NC}" | tee -a $LOG_FILE
            sudo apt update && sudo apt upgrade -y | tee -a $LOG_FILE
            ;;
        fedora|rhel|centos)
            echo -e "${YELLOW}[INFO] Fedora/Red Hat tabanlı sistem tespit edildi.${NC}" | tee -a $LOG_FILE
            sudo dnf update -y | tee -a $LOG_FILE
            ;;
        arch|manjaro)
            echo -e "${YELLOW}[INFO] Arch tabanlı sistem tespit edildi.${NC}" | tee -a $LOG_FILE
            sudo pacman -Syu --noconfirm | tee -a $LOG_FILE
            ;;
        opensuse)
            echo -e "${YELLOW}[INFO] OpenSUSE sistemi tespit edildi.${NC}" | tee -a $LOG_FILE
            sudo zypper update -y | tee -a $LOG_FILE
            ;;
        *)
            echo -e "${RED}[ERROR] Sistem bilgisi alınamadı.${NC}" | tee -a $LOG_FILE
            exit 1
            ;;
    esac
}

# disk alanı kontrolu
check_disk_usage() {
    local usage=$(df / | grep / | awk '{print $5}' | sed 's/%//')
    local threshold=80
    if [ "$usage" -ge "$threshold" ]; then
        echo -e "${RED}[WARNING] Disk kullanımı %$usage. Lütfen boş alan oluşturun.${NC}" | tee -a $LOG_FILE
    else
        echo -e "${GREEN}[INFO] Disk kullanımı %$usage. Her şey yolunda.${NC}" | tee -a $LOG_FILE
    fi
}

# guncellemeden sonra gereksiz dosyaları temizleme
cleanup_system() {
    local distro=$(detect_distro)
    case "$distro" in
        ubuntu|debian)
            sudo apt autoremove -y | tee -a $LOG_FILE
            sudo apt clean | tee -a $LOG_FILE
            ;;
        fedora|rhel|centos)
            sudo dnf autoremove -y | tee -a $LOG_FILE
            ;;
        arch|manjaro)
            sudo pacman -Rns $(pacman -Qtdq) --noconfirm | tee -a $LOG_FILE
            ;;
        opensuse)
            sudo zypper clean | tee -a $LOG_FILE
            ;;
        *)
            echo -e "${RED}[ERROR] Temizlik işlemi başarısız oldu.${NC}" | tee -a $LOG_FILE
            ;;
    esac
    echo -e "${GREEN}[INFO] Sistem temizlik işlemi tamamlandı.${NC}" | tee -a $LOG_FILE
}

# script
main() {
    echo -e "${GREEN}[START] Sistem Güncellemesi Başlatıldı: $(date)${NC}" | tee -a $LOG_FILE
    check_disk_usage
    update_system
    cleanup_system
    echo -e "${GREEN}[END] Sistem Güncellemesi Tamamlandı: $(date)${NC}" | tee -a $LOG_FILE
}

# root yetkisi kontrolu root yetkisi olmadan calismaz 
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] Lütfen scripti root olarak çalıştırın.${NC}"
    exit 1
fi

# script calistirma
main
