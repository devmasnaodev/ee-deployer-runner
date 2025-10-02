#!/bin/bash
set -e

echo "🚀 Iniciando ee-deployer-runner..."

# Definir valores padrão se não estiverem definidos
SSH_PORT=${SSH_PORT:-2232}
CONTAINER_NAME=${CONTAINER_NAME:-ee-deployer-runner}

echo "⚙️  Configurações:"
echo "   🔗 Porta SSH externa: $SSH_PORT"
echo "   📦 Nome do container: $CONTAINER_NAME"

# Gerar host keys se não existirem
echo "📋 Gerando chaves SSH do host..."
ssh-keygen -A

echo "📁 Configurando diretórios e permissões..."

# Garantir que a pasta ~/.ssh do www-data exista
mkdir -p /var/www/.ssh
chown -R www-data:www-data /var/www/.ssh
chmod 700 /var/www/.ssh

# Função para configurar SSH
setup_ssh() {
    echo "🔐 Configurando SSH..."
    
    # Configurar permissões para todos os arquivos SSH
    if [ -d "/var/www/.ssh" ] && [ "$(ls -A /var/www/.ssh 2>/dev/null)" ]; then
        echo "📂 Configurando permissões dos arquivos SSH..."
        
        # Configurar permissões específicas por tipo de arquivo
        find /var/www/.ssh -type f -name "*.pub" -exec chmod 644 {} \; 2>/dev/null || true
        find /var/www/.ssh -type f ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
        
        # Verificar arquivos específicos
        if [ -f /var/www/.ssh/authorized_keys ]; then
            echo "✅ Encontrado authorized_keys"
            chmod 600 /var/www/.ssh/authorized_keys
        fi
        
        if [ -f /var/www/.ssh/known_hosts ]; then
            echo "✅ Encontrado known_hosts"
            chmod 644 /var/www/.ssh/known_hosts
        else
            echo "⚠️  known_hosts não encontrado, criando um vazio"
            touch /var/www/.ssh/known_hosts
            chown www-data:www-data /var/www/.ssh/known_hosts
            chmod 644 /var/www/.ssh/known_hosts
        fi
        
        # Garantir ownership correto
        chown -R www-data:www-data /var/www/.ssh
        echo "✅ Permissões SSH configuradas"
    else
        echo "⚠️  Nenhum arquivo SSH encontrado"
    fi
}

# Executar configuração SSH
setup_ssh

echo "✅ Configuração concluída!"
echo "🔗 SSH disponível na porta $SSH_PORT (externa)"
echo "👤 Usuário: www-data"
echo "💡 Conecte com: ssh -p $SSH_PORT www-data@localhost"

# Iniciar sshd em foreground
echo "🎯 Iniciando servidor SSH..."
exec /usr/sbin/sshd -D -e