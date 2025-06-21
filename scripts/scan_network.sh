#!/bin/bash

# Script para verificar IPs disponíveis em uma rede

function check_ansible_installation {
    if ! command -v ansible-playbook &> /dev/null; then
        echo "Ansible não encontrado. Instalando..."
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository --yes --update ppa:ansible/ansible
        sudo apt install -y ansible
        echo "Ansible instalado com sucesso!"
    else
        echo "Ansible já está instalado."
    fi
}

function usage {
    echo "Uso: $0 [rede]"
    echo "Redes disponíveis:"
    echo "  servidores-1608"
    echo "  zdm-abaixofw-1104"
    echo "  zdm-desenvolvimento"
    echo "  zdm-homolog"
    echo "  zdm-ger-virtualizacao"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

# Verificar e instalar Ansible se necessário
check_ansible_installation

REDE=$1

case $REDE in
    servidores-1608)
        NETWORK_NAME="servidores-1608"
        NETWORK_PREFIX="192.168.11"
        ;;
    zdm-abaixofw-1104)
        NETWORK_NAME="zdm-abaixofw-1104"
        NETWORK_PREFIX="177.184.13"
        ;;
    zdm-desenvolvimento)
        NETWORK_NAME="zdm-desenvolvimento"
        NETWORK_PREFIX="192.168.14"
        ;;
    zdm-homolog)
        NETWORK_NAME="zdm-homolog"
        NETWORK_PREFIX="192.168.15"
        ;;
    zdm-ger-virtualizacao)
        NETWORK_NAME="zdm-ger-virtualizacao"
        NETWORK_PREFIX="192.168.12"
        ;;
    *)
        echo "Rede desconhecida: $REDE"
        usage
        ;;
esac

ansible-playbook playbooks/ip_scanner.yml -e "network_name=$NETWORK_NAME network_prefix=$NETWORK_PREFIX"