#!/bin/bash

# Script para facilitar a execução dos playbooks de configuração de rede

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
    echo "Uso: $0 [rede] [host] [--manual-ip IP] [--gateway GW]"
    echo "Redes disponíveis:"
    echo "  servidores-1608"
    echo "  zdm-abaixofw-1104"
    echo "  zdm-desenvolvimento"
    echo "  zdm-homolog"
    echo "  zdm-ger-virtualizacao"
    echo "  all - para todas as redes"
    echo ""
    echo "Host: opcional, nome do host específico a ser configurado"
    echo "--manual-ip: opcional, para definir um IP específico (desativa a atribuição automática)"
    echo "--gateway: opcional, para definir um gateway específico"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

# Verificar e instalar Ansible se necessário
check_ansible_installation

REDE=$1
HOST=$2
MANUAL_IP=""
AUTO_ASSIGN="true"
CUSTOM_GATEWAY=""

# Verificar parâmetros adicionais
shift 2
while [ "$#" -gt 0 ]; do
    case "$1" in
        --manual-ip)
            AUTO_ASSIGN="false"
            MANUAL_IP="$2"
            shift 2
            ;;
        --gateway)
            CUSTOM_GATEWAY="$2"
            shift 2
            ;;
        *)
            echo "Parâmetro desconhecido: $1"
            usage
            ;;
    esac
done

# Criar diretório de registro de IPs se não existir
mkdir -p ip_registry

case $REDE in
    servidores-1608)
        LIMIT="servidores_1608"
        NETWORK_NAME="servidores-1608"
        NETWORK_PREFIX="192.168.11"
        ;;
    zdm-abaixofw-1104)
        LIMIT="zdm_abaixofw_1104"
        NETWORK_NAME="zdm-abaixofw-1104"
        NETWORK_PREFIX="177.184.13"
        ;;
    zdm-desenvolvimento)
        LIMIT="zdm_desenvolvimento"
        NETWORK_NAME="zdm-desenvolvimento"
        NETWORK_PREFIX="192.168.14"
        ;;
    zdm-homolog)
        LIMIT="zdm_homolog"
        NETWORK_NAME="zdm-homolog"
        NETWORK_PREFIX="192.168.15"
        ;;
    zdm-ger-virtualizacao)
        LIMIT="zdm_ger_virtualizacao"
        NETWORK_NAME="zdm-ger-virtualizacao"
        NETWORK_PREFIX="192.168.12"
        ;;
    all)
        LIMIT="all"
        NETWORK_NAME=""
        NETWORK_PREFIX=""
        ;;
    *)
        echo "Rede desconhecida: $REDE"
        usage
        ;;
esac

if [ ! -z "$HOST" ]; then
    LIMIT="$HOST"
fi

EXTRA_VARS="auto_assign_ip=$AUTO_ASSIGN"

if [ "$AUTO_ASSIGN" == "false" ] && [ ! -z "$MANUAL_IP" ]; then
    EXTRA_VARS="$EXTRA_VARS ip_address=$MANUAL_IP"
fi

if [ ! -z "$NETWORK_NAME" ] && [ ! -z "$NETWORK_PREFIX" ]; then
    EXTRA_VARS="$EXTRA_VARS network_name=$NETWORK_NAME network_prefix=$NETWORK_PREFIX"
fi

if [ ! -z "$CUSTOM_GATEWAY" ]; then
    EXTRA_VARS="$EXTRA_VARS gateway=$CUSTOM_GATEWAY"
fi

ansible-playbook playbooks/main.yml -i inventory/hosts.ini -l $LIMIT -e "$EXTRA_VARS"