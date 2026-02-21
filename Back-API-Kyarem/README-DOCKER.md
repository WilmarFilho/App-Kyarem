# Rodando a API com Docker + Nginx

## 1) Pré-requisitos
- Docker
- Docker Compose (plugin)

## 2) Variáveis de ambiente
Crie (ou ajuste) um arquivo `.env` na raiz do projeto (mesmo nível do `docker-compose.yml`) com:

```env
# Banco (Supabase Postgres)
DB_URL=jdbc:postgresql://<host>:5432/postgres?sslmode=require
DB_USER=<user>
DB_PASSWORD=<password>

# JWT Issuer do Supabase
SUPABASE_JWT_ISSUER=https://<project-ref>.supabase.co/auth/v1

# Opcional
APP_PORT=8080
DB_POOL_SIZE=10
LOG_SECURITY=INFO
```

## 3) Subir os containers

```bash
docker compose up -d --build
```

## 4) Testes rápidos
- Health: `GET http://localhost/actuator/health`
- Swagger: `http://localhost/swagger-ui`

## 5) Logs

```bash
docker compose logs -f api
```

## 6) Parar

```bash
docker compose down
```

## HTTPS
Este compose sobe o Nginx em HTTP (porta 80). Para produção você pode:
- colocar um Load Balancer/Cloudflare fazendo TLS
- ou adicionar certbot/Let's Encrypt (recomendado quando tiver domínio)
