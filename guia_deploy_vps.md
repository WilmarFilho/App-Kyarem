# Guia Oficial de Deploy e Infraestrutura Kyarem

Este documento detalha o processo de deploy ponta a ponta para a nova arquitetura Kyarem (Multi-módulo), desde a configuração do DNS até a automação de CI/CD pelo GitHub Actions.

## 1. Apontamento de Domínio (DNS)

Antes de configurar o servidor, garanta que o tráfego chegará até a sua VPS.

1. Acesse o painel do seu provedor de domínio (ex: Registro.br, Cloudflare, Hostinger).
2. Vá até as configurações de **DNS**.
3. Crie um novo registro com as seguintes propriedades:
   - **Tipo:** `A`
   - **Nome / Host:** `kyarem`
   - **Valor / Aponta para:** `[IP_DA_SUA_VPS]` (ex: `165.22.180.XX`)
   - **TTL:** Padrão ou 3600 (1 hora)
4. Aguarde a propagação (geralmente poucos minutos na Cloudflare, pode levar mais em outros provedores).

---

## 2. Configuração das GitHub Secrets

Para que a automação (CI/CD) que criamos funcione, o GitHub precisa ter permissão para acessar a sua VPS e injetar o arquivo de produção. Vá no repositório do Github -> **Settings** -> **Secrets and variables** -> **Actions** e adicione:

### 2.1 Como gerar a chave SSH para o GitHub Actions
Para que o GitHub Actions acesse sua VPS de forma segura, você deve usar chaves SSH (nunca senhas).

1. Na sua própria máquina ou na VPS, rode o comando:
   ```bash
   ssh-keygen -t ed25519 -C "deploy-kyarem" -f ./deploy_kyarem_key
   ```
2. Isso vai gerar dois arquivos:
   - `deploy_kyarem_key.pub` (Chave **Pública**)
   - `deploy_kyarem_key` (Chave **Privada**)
3. **Na sua VPS:** Adicione o conteúdo da chave **PÚBLICA** dentro do arquivo `~/.ssh/authorized_keys` do usuário que fará o deploy (ex: `root` ou `ubuntu`).
   ```bash
   echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDn4b4u9FaFd3QFFDjNPBoz+n4eUPG6va8+Ct4XHJxw3 deploy-kyarem" >> ~/.ssh/authorized_keys
   ```
4. **No GitHub Secrets:** Copie todo o conteúdo da chave **PRIVADA** (o arquivo `deploy_kyarem_key` que começa com `-----BEGIN OPENSSH PRIVATE KEY-----`) e cole como valor da secret `VPS_SSH_KEY` listada abaixo.

> [!IMPORTANT]  
> Nunca coloque aspas duplas por fora dos valores nas secrets do Github, pois o script Bash já vai tratá-las de forma raw.

| Nome da Secret | O que colocar | Exemplo |
| :--- | :--- | :--- |
| `VPS_HOST` | O IP público da sua VPS | `165.22.180.xx` |
| `VPS_USER` | Usuário root ou de deploy | `root` |
| `VPS_SSH_KEY` | Sua chave privada gerada na VPS (`id_rsa` ou `id_ed25519`) | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `VPS_DEPLOY_PATH` | Onde os containers vão rodar na VPS | `/root/deploy/kyarem` ou `/opt/kyarem` |
| `ENV_PROD` | O conteúdo literal do seu `.env.prod` | *(Veja o modelo abaixo)* |

### Modelo para a secret `ENV_PROD`
Copie o bloco abaixo, troque as senhas de banco e chaves do Supabase, e cole **diretamente como valor** da secret `ENV_PROD`:

```env
SUPABASE_URL=https://hlgnackuzfhkhloemtey.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci... [SUA CHAVE AQUI]
SUPABASE_JWT_ISSUER=https://hlgnackuzfhkhloemtey.supabase.co/auth/v1
SUPABASE_BUCKET_SUMULAS=sumulas

DB_URL=jdbc:postgresql://db.hlgnackuzfhkhloemtey.supabase.co:5432/postgres
DB_USER=postgres
DB_PASSWORD=[SENHA DO BANCO]

DB_POOL_SIZE=10
DB_POOL_MIN_IDLE=2
DB_POOL_CONN_TIMEOUT_MS=30000
DB_POOL_IDLE_TIMEOUT_MS=600000
DB_POOL_MAX_LIFETIME_MS=1800000

RABBITMQ_HOST=kyarem_rabbitmq
RABBITMQ_PORT=5672
RABBITMQ_USER=kyarem
RABBITMQ_PASSWORD=[UMA SENHA FORTE PARA O RABBIT]
RABBITMQ_VHOST=/kyarem

JWT_SECRET=[SUA CHAVE JWT AQUI]

APP_PORT=8080
SERVER_FORWARD_HEADERS_STRATEGY=framework
LOG_SECURITY=INFO

OUTBOX_POLL_INTERVAL_MS=2000
OUTBOX_RETRY_INTERVAL_MS=30000

LOG_LEVEL=INFO
```

---

## 3. Configuração do Nginx na VPS

Como o tráfego da internet chega sempre nas portas `80` e `443`, o Nginx na sua VPS servirá como a "porta de entrada" (Proxy Reverso) e dividirá o tráfego para os containers corretos do Docker (`8083` para API e `8084` para o SSE).

**Passo 1:** Conecte via SSH na VPS.
**Passo 2:** Crie o arquivo de configuração:
```bash
sudo nano /etc/nginx/sites-available/kyarem.nkwflow.com
```

**Passo 3:** Cole o conteúdo do arquivo gerado em `deploy/nginx/kyarem.nkwflow.com.conf`.

> [!TIP]  
> **Atenção aos blocos importantes:**
> - O bloco `location /events/` está configurado com `proxy_buffering off` e `proxy_read_timeout 3600s`. Isso é fundamental para que a tecnologia de Realtime/SSE funcione, senão o Nginx "prende" os placares na memória dele e o celular do usuário não os recebe.

**Passo 4:** Ative o site criando um link simbólico:
```bash
sudo ln -s /etc/nginx/sites-available/kyarem.nkwflow.com /etc/nginx/sites-enabled/
```

**Passo 5:** Teste as configurações e reinicie o Nginx:
```bash
sudo nginx -t
sudo systemctl restart nginx
```

---

## 4. Gerar o Certificado SSL (HTTPS)

Execute o certbot para criptografar a comunicação. O Certbot irá ler automaticamente seu arquivo do Nginx e instalar os certificados.

```bash
sudo certbot --nginx -d kyarem.nkwflow.com
```

Siga as instruções na tela (colocar e-mail, aceitar termos).

---

## 5. Primeiro Deploy

Após as secrets criadas e a infra pronta:

1. Vá na aba **Actions** no seu repositório Github.
2. Selecione o workflow **🚀 Deploy — Kyarem Backend**.
3. Clique em **Run workflow**.

A pipeline fará o download das imagens, criará o `.env` de produção, e levantará todos os containers (`kyarem_api_core`, `kyarem_rabbitmq`, etc) usando o `docker-compose.yml`. 

> [!NOTE]  
> Você pode acompanhar tudo abrindo o terminal da VPS e rodando:
> `docker ps` para ver os serviços e `docker logs -f kyarem_api_core` para acompanhar o backend subindo.

---

## 6. Como Debugar os Containers na VPS

Com a nova arquitetura rodando vários containers, você precisará monitorar e inspecionar os serviços diretamente na VPS caso algo falhe.

1. **Acesse a pasta de deploy:**
   Primeiro, entre na pasta onde o Github Actions joga o `docker-compose.yml` e o `.env` (ex: `cd /root/deploy/kyarem`).

2. **Verificar o status dos containers:**
   ```bash
   docker compose ps
   ```
   Isso mostrará quais estão `Up` (rodando), `Restarting` (falhando e tentando subir) ou `Exited` (parados). O `kyarem_rabbitmq` deve ficar sempre `healthy`.

3. **Ver os logs de um container específico:**
   Os logs são cruciais para ver erros da API ou dos workers. Use o parâmetro `-f` para acompanhar em tempo real.
   - Logs da API principal: `docker logs -f kyarem_api_core`
   - Logs do Outbox: `docker logs -f kyarem_outbox_publisher`
   - Logs do Realtime (SSE): `docker logs -f kyarem_realtime_gateway`
   - *Dica:* Para ver as últimas 100 linhas, use `docker logs -n 100 kyarem_api_core`

4. **Reiniciar todos ou apenas um container:**
   Se você atualizou o `.env` na mão e quer aplicar:
   ```bash
   # Reinicia apenas a API
   docker compose restart kyarem_api_core
   
   # Recarrega todos lendo o .env e docker-compose atualizados
   docker compose up -d
   ```

5. **Entrar no container para investigar:**
   Se precisar rodar comandos de dentro do container (ex: dar ping no rabbitmq da rede interna):
   ```bash
   docker exec -it kyarem_api_core /bin/sh
   ```

6. **Inspecionar uso de memória e CPU:**
   Com vários serviços rodando, fique de olho nos recursos da VPS:
   ```bash
   docker stats
   ```
