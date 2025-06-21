# Template Ansible para Configuração de Rede Ubuntu 24.04 (Sem VLANs)

### Vou atualizar a estrutura de template removendo as configurações de VLAN de todos os arquivos. Aqui está a versão revisada:

| ## 1. Estrutura de Diretórios (Mantida a mesma) |
|---|



```
ubuntu-network-template/
├── README.md                        # Documentação do template
├── playbooks/
│   ├── main.yml                     # Playbook principal
│   ├── ip_scanner.yml               # Playbook para verificar IPs disponíveis
│   └── network_config.yml           # Playbook para configuração de rede
├── inventory/
│   ├── hosts.ini                    # Arquivo de inventário
│   └── group_vars/                  # Variáveis de grupo
│       ├── all.yml                  # Variáveis globais
│       ├── servidores_1608.yml      # Variáveis para Servidores-1608
│       ├── zdm_abaixofw_1104.yml    # Variáveis para ZDM-ABAIXOFW-1104
│       ├── zdm_desenvolvimento.yml  # Variáveis para ZDM-Desenvolvimento
│       ├── zdm_homolog.yml          # Variáveis para ZDM-Homolog
│       └── zdm_ger_virtualizacao.yml # Variáveis para ZDM-Ger Virtualizacao
├── templates/
│   └── 01-netcfg.yaml.j2            # Template Netplan
├── roles/
│   ├── common/                      # Role para tarefas comuns
│   │   ├── tasks/
│   │   │   └── main.yml             # Tarefas comuns (atualização, pacotes básicos)
│   │   └── defaults/
│   │       └── main.yml             # Valores padrão
│   ├── network/                     # Role para configuração de rede
│   │   ├── tasks/
│   │   │   └── main.yml             # Tarefas de configuração de rede
│   │   ├── templates/
│   │   │   └── 01-netcfg.yaml.j2    # Template Netplan
│   │   └── defaults/
│   │       └── main.yml             # Valores padrão
│   └── vmware/                      # Role para VMware Tools
│       ├── tasks/
│       │   └── main.yml             # Tarefas de instalação do VMware Tools
│       └── defaults/
│           └── main.yml             # Valores padrão
├── ip_registry/                     # Diretório para registrar IPs atribuídos
│   ├── .gitkeep                     # Para manter o diretório no git
│   └── README.md                    # Documentação sobre o registro de IPs
└── scripts/
    ├── deploy.sh                    # Script para facilitar a execução
    └── scan_network.sh              # Script para verificar IPs disponíveis
```

## 2. Conteúdo dos Arquivos Atualizados

### README.md
```markdown
# Template Ansible para Configuração de Rede Ubuntu 24.04

Este template fornece uma estrutura completa para configurar a rede em servidores Ubuntu 24.04, incluindo:

- Configuração de rede com Netplan
- Atribuição automática de IPs (a partir do .101)
- Configuração de hostname
- Atualização de pacotes
- Instalação de pacotes básicos de rede
- Instalação do VMware Tools

## Redes Suportadas

- Servidores-1608 (192.168.11.0/24)
- ZDM-ABAIXOFW-1104 (177.184.13.0/24)
- ZDM-Desenvolvimento (192.168.14.0/24)
- ZDM-Homolog (192.168.15.0/24)
- ZDM-Ger Virtualizacao (192.168.12.0/24)

## Requisitos

- Ansible 2.9 ou superior
- Python 3.6 ou superior
- Utilitário jq (`apt-get install jq`)
- Acesso SSH aos servidores de destino

## Uso Básico

1. Configure o inventário em `inventory/hosts.ini`
2. Execute o script de implantação:

```bash
./scripts/deploy.sh servidores-1608 servidor1
```

Para mais detalhes, consulte a documentação completa.
```

### templates/01-netcfg.yaml.j2 (Atualizado sem VLANs)
```yaml
# Configuração de rede para {{ network_name }}
network:
  version: 2
  renderer: networkd
  ethernets:
    {{ interface_rede }}:
      dhcp4: no
      addresses:
        - {{ ip_address }}
      routes:
        - to: default
          via: {{ gateway }}
      nameservers:
        addresses: {{ dns_servers }}
```

### inventory/group_vars/servidores_1608.yml (Atualizado sem VLAN)
```yaml
---
network_name: "servidores-1608"
network_prefix: "192.168.11"
ip_address: "192.168.11.101/24"  # Usado apenas se auto_assign_ip for false
gateway: "192.168.11.1"
dns_servers: 
  - "192.168.11.51"
novo_hostname: "srv-1608"  # O número do IP será adicionado automaticamente
```

### inventory/group_vars/zdm_abaixofw_1104.yml (Atualizado sem VLAN)
```yaml
---
network_name: "zdm-abaixofw-1104"
network_prefix: "177.184.13"
ip_address: "177.184.13.101/24"  # Usado apenas se auto_assign_ip for false
gateway: "177.184.13.1"
dns_servers: 
  - "201.49.216.57"
  - "201.49.216.58"
novo_hostname: "zdm-fw"  # O número do IP será adicionado automaticamente
```

### inventory/group_vars/zdm_desenvolvimento.yml (Atualizado sem VLAN)
```yaml
---
network_name: "zdm-desenvolvimento"
network_prefix: "192.168.14"
ip_address: "192.168.14.101/24"  # Usado apenas se auto_assign_ip for false
gateway: "192.168.14.1"
dns_servers: 
  - "192.168.11.51"
novo_hostname: "zdm-dev"  # O número do IP será adicionado automaticamente
```

### inventory/group_vars/zdm_homolog.yml (Atualizado sem VLAN)
```yaml
---
network_name: "zdm-homolog"
network_prefix: "192.168.15"
ip_address: "192.168.15.101/24"  # Usado apenas se auto_assign_ip for false
gateway: "192.168.15.1"
dns_servers: 
  - "192.168.11.51"
novo_hostname: "zdm-hml"  # O número do IP será adicionado automaticamente
```

### inventory/group_vars/zdm_ger_virtualizacao.yml (Atualizado sem VLAN)
```yaml
---
network_name: "zdm-ger-virtualizacao"
network_prefix: "192.168.12"
ip_address: "192.168.12.101/24"  # Usado apenas se auto_assign_ip for false
gateway: "192.168.12.1"
dns_servers: 
  - "192.168.11.51"
novo_hostname: "zdm-virt"  # O número do IP será adicionado automaticamente
```

### roles/network/defaults/main.yml (Atualizado sem VLAN)
```yaml
---
# Valores padrão para a role network
auto_assign_ip: true
interface_rede: "ens192"
ip_address: "192.168.1.100/24"
gateway: "192.168.1.1"
dns_servers: ["8.8.8.8", "8.8.4.4"]
novo_hostname: "ubuntu-server"
```

### scripts/deploy.sh (Mantido o mesmo, sem referências a VLAN)
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

## 3. Como Usar o Template (Mantido o mesmo)

1. **Clonar o Repositório**:
   ```bash
   git clone <url-do-repositorio> ubuntu-network-template
   cd ubuntu-network-template
   ```

2. **Tornar os Scripts Executáveis**:
   ```bash
   chmod +x scripts/*.sh
   ```

### 3. **Configurar o Inventário**:

| Edite o arquivo `inventory/hosts.ini` para adicionar seus servidores. |
|---|



4. **Verificar IPs Disponíveis**:
   ```bash
   ./scripts/scan_network.sh zdm-desenvolvimento
   ```

5. **Executar o Playbook**:
   ```bash
   # Com atribuição automática de IP
   ./scripts/deploy.sh zdm-desenvolvimento zdm-dev-1
   
   # Com IP específico
   ./scripts/deploy.sh zdm-desenvolvimento zdm-dev-1 --manual-ip 192.168.14.150/24
   ```

## 4. Personalização (Atualizado sem referências a VLAN)

### - **Adicionar Nova Rede**:

| 1. Crie um novo arquivo em `inventory/group_vars/` |
|---|


  2. Adicione o grupo ao arquivo `inventory/hosts.ini`
  3. Atualize os scripts em `scripts/` para incluir a nova rede

### - **Modificar Pacotes**:

| Edite o arquivo `inventory/group_vars/all.yml` para ajustar a lista de pacotes. |
|---|



### - **Configurações de Interface**:

| Ajuste o parâmetro `interface_rede` nos arquivos de variáveis de grupo se necessário. |
|---|



## 5. Considerações Finais

### Esta estrutura de template fornece uma base sólida e organizada para configurar a rede em servidores Ubuntu 24.04. Ela segue as melhores práticas do Ansible, como:

| 1. **Separação de Responsabilidades**: Usando roles para diferentes aspectos da configuração. |
|---|


2. **Reutilização**: Templates e variáveis são organizados para facilitar a reutilização.
3. **Flexibilidade**: Suporte para atribuição automática ou manual de IPs.
4. **Documentação**: README.md detalhado e comentários nos arquivos.
5. **Escalabilidade**: Fácil de adicionar novas redes ou servidores.

A estrutura também inclui recursos avançados como verificação de disponibilidade de IPs e registro de IPs atribuídos, tornando-a adequada para ambientes de produção.

## Resumo das Alterações

1. Removidas todas as referências a VLANs do template Netplan
2. Removido o parâmetro `vlan_id` de todos os arquivos de variáveis
3. Simplificada a configuração de rede para usar apenas interfaces Ethernet diretas
4. Atualizada a documentação para remover menções a VLANs
5. Mantida toda a funcionalidade de atribuição automática de IPs e configuração de rede

Esta versão simplificada mantém todas as funcionalidades importantes do template original, mas sem a complexidade adicional da configuração de VLANs.