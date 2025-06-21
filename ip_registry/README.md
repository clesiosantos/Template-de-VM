# Registro de IPs

Este diretório contém arquivos JSON que registram os IPs atribuídos para cada rede.

## Formato

Cada arquivo segue o formato:

```json
{
  "hostname1": "101",
  "hostname2": "102",
  "20230615T120000": "103"  // IP reservado mas ainda não atribuído
}
```

Os IPs são armazenados como o último octeto apenas (por exemplo, "101" para 192.168.11.101).

Arquivos
servidores-1608.json: IPs da rede 192.168.11.0/24
zdm-abaixofw-1104.json: IPs da rede 177.184.13.0/24
zdm-desenvolvimento.json: IPs da rede 192.168.14.0/24
zdm-homolog.json: IPs da rede 192.168.15.0/24
zdm-ger-virtualizacao.json: IPs da rede 192.168.12.0/24

### scripts/deploy.sh
```bash
#!/bin/bash

# Script para facilitar a execução dos playbooks de configuração de rede

function usage {
    echo "Uso: $0 [rede] [host] [--manual-ip IP]"
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
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

REDE=$1
HOST=$2
MANUAL_IP=""
AUTO_ASSIGN="true"

# Verificar se há parâmetro de IP manual
for arg in "$@"; do
    if [[ $arg == "--manual-ip" ]]; then
        AUTO_ASSIGN="false"
        MANUAL_IP=${@: $OPTIND:1}
    fi
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

ansible-playbook playbooks/main.yml -i inventory/hosts.ini -l $LIMIT -e "$EXTRA_VARS"
```