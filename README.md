# ee-deployer-runner

Este projeto fornece uma imagem Docker para automação de deploys e operações via SSH, utilizando o usuário seguro `www-data`.

## Recursos
- Base PHP 8.4 CLI
- Instalação de ferramentas essenciais: git, unzip, zip, less, mariadb-client, rsync, curl, openssh-server
- Composer e WP-CLI prontos para uso
- Diretórios `.ssh` e `.cache` configurados para o usuário `www-data`
- Configuração customizada do SSH
- HEALTHCHECK para monitoramento do container
- Exemplo de entrypoint adaptável

## Segurança
- O container executa como `www-data` (não root)
- Diretórios sensíveis possuem permissões restritas
- Recomenda-se configurar o arquivo `sshd_config` com:
  ```
  PermitRootLogin no
  PasswordAuthentication no
  AllowUsers www-data
  ```
- Utilize autenticação por chave SSH

## Configuração

### Arquivo .env

O projeto usa um arquivo `.env` para configurações:

```bash
# Editar configurações conforme necessário
vim .env
```

**Configurações disponíveis:**
- `SSH_PORT`: Porta externa do SSH (padrão: 2232)
- `CONTAINER_NAME`: Nome do container (padrão: ee-deployer-runner)  
- `IMAGE_NAME`: Nome da imagem (padrão: ee-deployer-runner:latest)


## Setup SSH

1. **Crie e configure a pasta .ssh:**
   ```bash
   mkdir -p .ssh
   cp ~/.ssh/id_ed25519 .ssh/          # Chave privada
   cp ~/.ssh/id_ed25519.pub .ssh/      # Chave pública  
   cp ~/.ssh/authorized_keys .ssh/     # Chaves autorizadas
   cp ~/.ssh/known_hosts .ssh/         # Hosts conhecidos (opcional)
   ```

2. **Build e execução:**
   ```bash
   docker-compose build
   docker-compose up -d
   ```

### Conectar via SSH
```bash
# Usando a porta padrão (2232)
ssh -p 2232 www-data@localhost
```

Os arquivos SSH serão copiados durante o build com permissões corretas:
- **Chaves privadas:** 600
- **Chaves públicas (.pub):** 644
- **Diretório .ssh:** 700

## Script de Gerenciamento

O projeto inclui um script `manage-files.sh` para facilitar operações comuns:

```bash
# Tornar executável (primeira vez)
chmod +x manage-files.sh

# Copiar apenas authorized_keys para container em execução
./manage-files.sh copy-authorized-keys

# Copiar pasta .ssh completa para container em execução  
./manage-files.sh copy-ssh-folder

# Acessar shell do container
./manage-files.sh shell

# Ver logs do container
./manage-files.sh logs

# Ver ajuda
./manage-files.sh help
```

## Estrutura do projeto
```
.
├── docker-compose.yml
├── Dockerfile
├── .dockerignore         # Arquivos excluídos do build context
├── .env                  # Configurações do projeto
├── .ssh/                 # Pasta com arquivos SSH
│   ├── authorized_keys   # Chaves públicas autorizadas
│   ├── id_rsa           # Chave privada (opcional)
│   ├── id_rsa.pub       # Chave pública (opcional)
│   └── known_hosts      # Hosts conhecidos (opcional)
├── manage-files.sh       # Script para gerenciar o container
└── files/
    ├── entrypoint.sh
    └── sshd_config
```

**Importante:** 
- O arquivo `.env` não está no `.gitignore` pois contém apenas configurações básicas
- Adicione informações sensíveis ao `.gitignore` se necessário

## Contribuição
- Sugestões e PRs são bem-vindos

## Licença
Consulte o arquivo LICENSE para detalhes.
