#!/bin/bash

# Script para verificar IPs disponíveis em uma rede sem usar Ansible

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
START_IP=101
END_IP=254

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

echo "Verificando IPs disponíveis na rede $NETWORK_NAME ($NETWORK_PREFIX.0/24)..."

# Criar diretório de registro se não existir
mkdir -p ip_registry

# Verificar se o arquivo de registro existe
REGISTRY_FILE="ip_registry/${NETWORK_NAME}.json"
if [ ! -f "$REGISTRY_FILE" ]; then
    echo "{}" > "$REGISTRY_FILE"
fi

# Ler IPs já registrados
REGISTERED_IPS=$(grep -o '"[0-9]\+"' "$REGISTRY_FILE" 2>/dev/null | tr -d '"' | sort -n)

# Inicializar array de IPs para verificar
declare -a IPS_TO_CHECK
for ((i=START_IP; i<=END_IP; i++)); do
    # Verificar se o IP já está registrado
    if ! echo "$REGISTERED_IPS" | grep -q "^$i$"; then
        IPS_TO_CHECK+=($i)
    fi
done

# Verificar IPs disponíveis
AVAILABLE_IPS=()
for IP in "${IPS_TO_CHECK[@]}"; do
    echo -n "Verificando $NETWORK_PREFIX.$IP... "
    if ! ping -c 1 -W 1 $NETWORK_PREFIX.$IP > /dev/null 2>&1; then
        echo "disponível"
        AVAILABLE_IPS+=($IP)
    else
        echo "em uso"
    fi
done

# Exibir resultados
if [ ${#AVAILABLE_IPS[@]} -gt 0 ]; then
    echo ""
    echo "IPs disponíveis na rede $NETWORK_NAME:"
    for IP in "${AVAILABLE_IPS[@]}"; do
        echo "$NETWORK_PREFIX.$IP"
    done
    
    # Salvar o primeiro IP disponível como pendente
    FIRST_IP=${AVAILABLE_IPS[0]}
    TIMESTAMP=$(date +%Y%m%dT%H%M%S)
    
    # Usar jq se disponível, ou uma abordagem alternativa
    if command -v jq > /dev/null; then
        TEMP_FILE=$(mktemp)
        jq '. + {"'$TIMESTAMP'": "'$FIRST_IP'"}' "$REGISTRY_FILE" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$REGISTRY_FILE"
    else
        # Abordagem alternativa sem jq
        CONTENT=$(cat "$REGISTRY_FILE")
        # Remover a última chave
        CONTENT=${CONTENT%}}
        # Adicionar a nova entrada
        if [ "$CONTENT" = "{" ]; then
            # Arquivo vazio
            CONTENT="$CONTENT"$TIMESTAMP": "$FIRST_IP"}"
        else
            # Arquivo com conteúdo
            CONTENT="$CONTENT, "$TIMESTAMP": "$FIRST_IP"}"
        fi
        echo "$CONTENT" > "$REGISTRY_FILE"
    fi
    
    echo ""
    echo "Primeiro IP disponível: $NETWORK_PREFIX.$FIRST_IP"
    echo "Este IP foi marcado como pendente no registro."
else
    echo ""
    echo "Não há IPs disponíveis na rede $NETWORK_NAME no intervalo $NETWORK_PREFIX.$START_IP a $NETWORK_PREFIX.$END_IP"
fi