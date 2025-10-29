FROM php:8.4-cli

# Instala dependências
RUN apt-get update && apt-get install -y \
    git unzip zip less mariadb-client rsync curl openssh-server vim \
    && rm -rf /var/lib/apt/lists/*

# Instalar e habilitar extensões PHP necessárias para WordPress (mysqli e pdo_mysql)
# Isso permite que o WP-CLI (php CLI) se conecte ao banco de dados
RUN docker-php-ext-install mysqli pdo pdo_mysql || \
    { echo "Failed to install mysqli/pdo_mysql via docker-php-ext-install"; exit 1; }

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Composer Cache
RUN mkdir -p /var/www/.cache/composer \
    && chown -R www-data:www-data /var/www/.cache

# Configurar usuário www-data corretamente
RUN usermod -s /bin/bash www-data \
    && usermod -d /var/www www-data

# Preparar estrutura de diretórios com permissões corretas
RUN mkdir -p /var/www/.ssh \
    && mkdir -p /var/www/.cache/composer \
    && mkdir -p /var/run/sshd \
    && mkdir -p /etc/ssh \
    && chmod 700 /etc/ssh \
    && chown -R www-data:www-data /var/www \
    && chmod 700 /var/www/.ssh

# Copiar configuração do SSH customizada
COPY ./files/sshd_config /etc/ssh/sshd_config
RUN chmod 600 /etc/ssh/sshd_config

# Copiar entrypoint adaptado
COPY ./files/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Definir diretório de trabalho
WORKDIR /var/www

# Copiar pasta .ssh completa (se existir)
COPY .ssh /var/www/.ssh
RUN if [ -d "/var/www/.ssh" ] && [ "$(ls -A /var/www/.ssh 2>/dev/null)" ]; then \
        chmod 700 /var/www/.ssh && \
        find /var/www/.ssh -type f -name "*.pub" -exec chmod 644 {} \; && \
        find /var/www/.ssh -type f ! -name "*.pub" -exec chmod 600 {} \; && \
        chown -R www-data:www-data /var/www/.ssh && \
        echo "SSH files copied and permissions set"; \
    else \
        echo "No SSH files found - creating empty .ssh directory"; \
        mkdir -p /var/www/.ssh && \
        chmod 700 /var/www/.ssh && \
        chown -R www-data:www-data /var/www/.ssh; \
    fi

# Expor porta SSH
EXPOSE 22

# Definir entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Adicionar HEALTHCHECK para monitorar o container
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep sshd || exit 1