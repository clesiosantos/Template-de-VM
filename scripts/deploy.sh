#!/bin/bash

# Script para configurar rede em servidores Ubuntu

function usage {
    echo "Uso: $0 [rede] [opções]"
    echo "Redes disponíveis:"
    echo "  servidores-1608"
    echo "  zdm-abaixofw-1104"
    echo "  zdm-desenvolvimento"
    echo "  zdm-homolog"
    echo "  zdm-ger-virtualizacao"
    echo ""
    echo "Opções:"
    echo "  --manual-ip IP    : Define um IP específico (desativa a atribuição automática)"
    echo "  --gateway GW      : Define um gateway específico"
    echo "  --hostname NOME   : Define um hostname personalizado (sem o sufixo numérico)"
    echo "  --full-hostname NOME : Define um hostname completo (ignora o padrão da rede e o sufixo numérico)"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

REDE=$1
MANUAL_IP=""
AUTO_ASSIGN="true"
CUSTOM_GATEWAY=""
CUSTOM_HOSTNAME=""
FULL_HOSTNAME=""

# Verificar parâmetros adicionais
shift 1
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
        --hostname)
            CUSTOM_HOSTNAME="$2"
            shift 2
            ;;
        --full-hostname)
            FULL_HOSTNAME="$2"
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
        NETWORK_NAME="servidores-1608"
        NETWORK_PREFIX="192.168.11"
        GATEWAY="${CUSTOM_GATEWAY:-192.168.11.1}"
        DNS_SERVERS="192.168.11.51"
        HOSTNAME_PREFIX="${CUSTOM_HOSTNAME:-srv-1608}"
        ;;
    zdm-abaixofw-1104)
        NETWORK_NAME="zdm-abaixofw-1104"
        NETWORK_PREFIX="177.184.13"
        GATEWAY="${CUSTOM_GATEWAY:-177.184.13.1}"
        DNS_SERVERS="201.49.216.57 201.49.216.58"
        HOSTNAME_PREFIX="${CUSTOM_HOSTNAME:-zdm-fw}"
        ;;
    zdm-desenvolvimento)
        NETWORK_NAME="zdm-desenvolvimento"
        NETWORK_PREFIX="192.168.14"
        GATEWAY="${CUSTOM_GATEWAY:-192.168.14.1}"
        DNS_SERVERS="192.168.11.51"
        HOSTNAME_PREFIX="${CUSTOM_HOSTNAME:-zdm-dev}"
        ;;
    zdm-homolog)
        NETWORK_NAME="zdm-homolog"
        NETWORK_PREFIX="192.168.15"
        GATEWAY="${CUSTOM_GATEWAY:-192.168.15.1}"
        DNS_SERVERS="192.168.11.51"
        HOSTNAME_PREFIX="${CUSTOM_HOSTNAME:-zdm-hml}"
        ;;
    zdm-ger-virtualizacao)
        NETWORK_NAME="zdm-ger-virtualizacao"
        NETWORK_PREFIX="192.168.12"
        GATEWAY="${CUSTOM_GATEWAY:-192.168.12.1}"
        DNS_SERVERS="192.168.11.51"
        HOSTNAME_PREFIX="${CUSTOM_HOSTNAME:-zdm-virt}"
        ;;
    *)
        echo "Rede desconhecida: $REDE"
        usage
        ;;
esac

# Determinar o IP a ser usado
if [ "$AUTO_ASSIGN" = "true" ]; then
    # Verificar IPs disponíveis
    echo "Verificando IPs disponíveis na rede $NETWORK_NAME ($NETWORK_PREFIX.0/24)..."
    
    # Verificar se o arquivo de registro existe
    REGISTRY_FILE="ip_registry/${NETWORK_NAME}.json"
    if [ ! -f "$REGISTRY_FILE" ]; then
        echo "{}" > "$REGISTRY_FILE"
    fi
    
    # Ler IPs já registrados
    REGISTERED_IPS=$(grep -o '"[0-9]\+"' "$REGISTRY_FILE" 2>/dev/null | tr -d '"' | sort -n)
    
    # Inicializar array de IPs para verificar
    START_IP=101
    END_IP=254
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
    
    # Verificar se há IPs disponíveis
    if [ ${#AVAILABLE_IPS[@]} -eq 0 ]; then
        echo "Não há IPs disponíveis na rede $NETWORK_NAME. Abortando."
        exit 1
    fi
    
    # Usar o primeiro IP disponível
    IP_LAST_OCTET=${AVAILABLE_IPS[0]}
    IP_ADDRESS="$NETWORK_PREFIX.$IP_LAST_OCTET/24"
    
    echo "Usando IP disponível: $IP_ADDRESS"
else
    # Usar o IP manual
    IP_ADDRESS="$MANUAL_IP"
    IP_LAST_OCTET=$(echo "$MANUAL_IP" | grep -o '[0-9]\+' | tail -1)
    
    echo "Usando IP manual: $IP_ADDRESS"
fi

# Definir o hostname
if [ -n "$FULL_HOSTNAME" ]; then
    # Usar o hostname completo personalizado
    HOSTNAME="$FULL_HOSTNAME"
else
    # Usar o prefixo da rede + último octeto do IP
    HOSTNAME="${HOSTNAME_PREFIX}-${IP_LAST_OCTET}"
fi

echo "Configurando a máquina com:"
echo "  IP: $IP_ADDRESS"
echo "  Gateway: $GATEWAY"
echo "  DNS: $DNS_SERVERS"
echo "  Hostname: $HOSTNAME"
echo ""

# Configurar hostname
echo "Configurando hostname..."
sudo hostnamectl set-hostname $HOSTNAME

# Atualizar /etc/hosts
echo "Atualizando /etc/hosts..."
sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1 $HOSTNAME/" /etc/hosts

# Gerar o arquivo de configuração Netplan
echo "Configurando rede com Netplan..."
NETPLAN_CONFIG="# Configuração de rede para $NETWORK_NAME
network:
  version: 2
  renderer: networkd
  ethernets:
    ens192:
      dhcp4: no
      addresses:
        - $IP_ADDRESS
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses: [$DNS_SERVERS]
"

# Criar o arquivo de configuração Netplan
sudo mkdir -p /etc/netplan
echo "$NETPLAN_CONFIG" | sudo tee /etc/netplan/01-netcfg.yaml > /dev/null
sudo chmod 644 /etc/netplan/01-netcfg.yaml
sudo netplan apply

# Atualizar pacotes
echo "Atualizando pacotes..."
sudo apt update

# Instalar pacotes básicos de rede
echo "Instalando pacotes básicos de rede..."
sudo apt install -y net-tools tcpdump nmap traceroute whois dnsutils netcat curl wget telnet iperf3

# Instalar VMware Tools se necessário
echo "Verificando se é necessário instalar VMware Tools..."
if sudo dmidecode -s system-product-name | grep -q 'VMware'; then
    echo "Instalando VMware Tools..."
    sudo apt install -y open-vm-tools open-vm-tools-desktop
fi

# Registrar IP como atribuído
REGISTRY_FILE="ip_registry/${NETWORK_NAME}.json"
if [ -f "$REGISTRY_FILE" ]; then
    HOSTNAME_SHORT=$(hostname -s)
    if command -v jq > /dev/null; then
        TEMP_FILE=$(mktemp)
        jq '. + {"'$HOSTNAME_SHORT'": "'$IP_LAST_OCTET'"}' "$REGISTRY_FILE" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$REGISTRY_FILE"
    else
        # Abordagem alternativa sem jq
        CONTENT=$(cat "$REGISTRY_FILE")
        # Remover a última chave
        CONTENT=${CONTENT%}}
        # Adicionar a nova entrada
        if [ "$CONTENT" = "{" ]; then
            # Arquivo vazio
            CONTENT="$CONTENT"$HOSTNAME_SHORT": "$IP_LAST_OCTET"}"
        else
            # Arquivo com conteúdo
            CONTENT="$CONTENT, "$HOSTNAME_SHORT": "$IP_LAST_OCTET"}"
        fi
        echo "$CONTENT" > "$REGISTRY_FILE"
    fi
fi

# Verificar se reboot é necessário
if [ -f /var/run/reboot-required ]; then
    echo "Reinicialização necessária. Reiniciando em 10 segundos..."
    sleep 10
    sudo reboot
else
    echo "Configuração concluída com sucesso!"
fi