#!/bin/bash

# Script para gerenciar o ee-deployer-runner

set -e

# Carregar variáveis do arquivo .env se existir
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Usar variável do .env ou fallback para valor padrão
CONTAINER_NAME="${CONTAINER_NAME:-ee-deployer-runner}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_help() {
    echo "🔧 Gerenciador do ee-deployer-runner"
    echo ""
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos disponíveis:"
    echo "  copy-authorized-keys  Copia arquivo authorized_keys para o container"
    echo "  copy-ssh-folder       Copia toda a pasta .ssh para o container"
    echo "  shell                 Abre shell no container como www-data"
    echo "  logs                  Mostra logs do container"
    echo ""
    echo "Exemplos:"
    echo "  $0 copy-authorized-keys"
    echo "  $0 copy-ssh-folder"
    echo "  $0 shell"
    echo "  $0 logs"
}

check_container() {
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        echo -e "${RED}❌ Container '$CONTAINER_NAME' não está rodando${NC}"
        exit 1
    fi
}

copy_authorized_keys() {
    echo -e "${YELLOW}🔐 Copiando authorized_keys para o container...${NC}"
    
    if [ ! -f ".ssh/authorized_keys" ]; then
        echo -e "${RED}❌ Arquivo 'authorized_keys' não encontrado no diretório atual${NC}"
        echo -e "${YELLOW}💡 Crie o arquivo com: echo 'sua-chave-ssh-publica' > authorized_keys${NC}"
        exit 1
    fi
    
    check_container
    
    # Copiar arquivo authorized_keys
    docker cp .ssh/authorized_keys "$CONTAINER_NAME:/tmp/authorized_keys"
    
    # Mover e ajustar permissões dentro do container
    docker exec -u root "$CONTAINER_NAME" bash -c "
        mkdir -p /var/www/.ssh &&
        mv /tmp/authorized_keys /var/www/.ssh/authorized_keys &&
        chmod 700 /var/www/.ssh &&
        chmod 600 /var/www/.ssh/authorized_keys &&
        chown -R www-data:www-data /var/www/.ssh &&
        echo 'authorized_keys configurado com sucesso!'
    "
    
    echo -e "${GREEN}✅ Arquivo authorized_keys copiado e configurado!${NC}"
}

copy_ssh_folder() {
    echo -e "${YELLOW}🔐 Copiando pasta .ssh para o container...${NC}"
    
    if [ ! -d ".ssh" ]; then
        echo -e "${RED}❌ Pasta '.ssh' não encontrada no diretório atual${NC}"
        echo -e "${YELLOW}💡 Crie a pasta com: mkdir .ssh && cp ~/.ssh/* .ssh/${NC}"
        exit 1
    fi
    
    if [ ! "$(ls -A .ssh 2>/dev/null)" ]; then
        echo -e "${RED}❌ Pasta '.ssh' está vazia${NC}"
        exit 1
    fi
    
    check_container
    
    # Copiar toda a pasta .ssh
    docker cp .ssh/. "$CONTAINER_NAME:/tmp/ssh_files/"
    
    # Mover e ajustar permissões dentro do container
    docker exec -u root "$CONTAINER_NAME" bash -c "
        mkdir -p /var/www/.ssh &&
        cp -r /tmp/ssh_files/* /var/www/.ssh/ &&
        chmod 700 /var/www/.ssh &&
        
        # Configurar permissões específicas por tipo de arquivo
        find /var/www/.ssh -type f -name '*.pub' -exec chmod 644 {} \; 2>/dev/null || true &&
        find /var/www/.ssh -type f ! -name '*.pub' -exec chmod 600 {} \; 2>/dev/null || true &&
        
        chown -R www-data:www-data /var/www/.ssh &&
        rm -rf /tmp/ssh_files &&
        echo 'Pasta .ssh configurada com sucesso!'
    "
    
    echo -e "${GREEN}✅ Pasta .ssh copiada e configurada!${NC}"
}

open_shell() {
    check_container
    
    echo -e "${YELLOW}🐚 Abrindo shell no container como www-data...${NC}"
    docker exec -it -u www-data "$CONTAINER_NAME" bash
}

show_logs() {
    echo -e "${YELLOW}📋 Mostrando logs do container...${NC}"
    docker logs -f "$CONTAINER_NAME"
}

# Main
case "$1" in
    "copy-authorized-keys")
        copy_authorized_keys
        ;;
    "copy-ssh-folder")
        copy_ssh_folder
        ;;
    "shell")
        open_shell
        ;;
    "logs")
        show_logs
        ;;
    "help"|"--help"|"-h"|"")
        print_help
        ;;
    *)
        echo -e "${RED}❌ Comando desconhecido: $1${NC}"
        echo ""
        print_help
        exit 1
        ;;
esac