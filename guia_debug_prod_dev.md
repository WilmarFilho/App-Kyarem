# Guia de Debug em Produção e Preparo do Ambiente de Desenvolvimento Kyarem

Este documento reúne o fluxo prático para duas frentes do backend Kyarem:

1. **Debugar a stack em produção na VPS**
2. **Preparar um ambiente local de desenvolvimento para implementar e validar mudanças**

O foco aqui é o backend multi-módulo localizado em `Back-API-Kyarem/`, com estes serviços:

- `back-api-kyarem-api-core`
- `back-api-kyarem-outbox-publisher`
- `back-api-kyarem-projection-worker`
- `back-api-kyarem-metrics-worker`
- `back-api-kyarem-realtime-gateway`
- `back-api-kyarem-rabbitmq`

---

## 1. Quando vale instalar Java localmente?

Sim. Para desenvolver e debugar esse backend com conforto, você deve instalar **Java 21** na sua máquina.

Sem Java local você até consegue:

- subir containers na VPS
- inspecionar logs remotamente
- usar Docker para parte do ambiente

Mas você **não consegue** com facilidade:

- rodar `./gradlew bootRun`
- gerar `bootJar`
- validar módulos individualmente
- depurar com breakpoints na IDE
- testar rapidamente ajustes em listeners, filas e startup do Spring

> [!TIP]
> A versão recomendada aqui é **JDK 21**, porque o projeto está configurado com `JavaLanguageVersion.of(21)` no `build.gradle` raiz.

---

## 2. O que instalar na máquina de desenvolvimento

Para trabalhar no backend Kyarem, o ambiente mínimo recomendado é:

1. **JDK 21**
2. **Docker Desktop** ou Docker Engine
3. **Git**
4. **Uma IDE Java**
   - IntelliJ IDEA Community/Ultimate, ou
   - VS Code com extensões Java

### 2.1 Confirmar Java

Depois de instalar, valide:

```bash
java -version
javac -version
```

O esperado é aparecer algo como Java 21.

No Windows, se o `gradlew.bat` reclamar de `JAVA_HOME`, configure a variável:

```powershell
$env:JAVA_HOME="C:\Program Files\Eclipse Adoptium\jdk-21"
$env:Path="$env:JAVA_HOME\bin;$env:Path"
java -version
```

Para persistir, ajuste o `JAVA_HOME` nas variáveis de ambiente do sistema.

### 2.2 Confirmar Docker

```bash
docker --version
docker compose version
```

---

## 3. Estrutura do backend Kyarem

O projeto backend está em:

`Back-API-Kyarem/`

Ele é um projeto Gradle multi-módulo com:

- `api-core` — API principal e migrations Flyway
- `outbox-publisher` — publica eventos no RabbitMQ
- `projection-worker` — consome eventos e atualiza read models
- `metrics-worker` — recalcula rankings e métricas
- `realtime-gateway` — entrega eventos SSE

---

## 4. Preparar `.env` local

Dentro de `Back-API-Kyarem/`, copie o template:

```bash
cp .env.example .env
```

No Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Depois preencha os valores reais, principalmente:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_JWT_ISSUER`
- `DB_URL`
- `DB_USER`
- `DB_PASSWORD`
- `RABBITMQ_USER`
- `RABBITMQ_PASSWORD`
- `JWT_SECRET`

> [!IMPORTANT]
> O `.env` local precisa apontar para um banco que você realmente possa usar para desenvolvimento. Se for usar o Supabase de produção, muito cuidado.

---

## 5. Subir o RabbitMQ localmente

Para desenvolvimento, o caminho mais prático é subir só o broker via Docker e rodar os módulos Java pela IDE ou Gradle.

Entre em `Back-API-Kyarem/` e rode:

```bash
docker compose up -d back-api-kyarem-rabbitmq
```

Verifique:

```bash
docker compose ps
docker logs -f back-api-kyarem-rabbitmq
```

Se quiser acessar a UI do RabbitMQ localmente:

- Management: `http://localhost:15672` se você expuser a porta no compose local
- No compose atual ela está em `expose`, não em `ports`

Se precisar mesmo da UI local, você pode temporariamente mapear a porta em um compose específico de dev.

---

## 6. Rodar os módulos localmente

Abra o terminal em `Back-API-Kyarem/`.

### 6.1 Subir a API principal

```bash
./gradlew :api-core:bootRun
```

No Windows:

```powershell
.\gradlew.bat :api-core:bootRun
```

Quando a API sobe bem, ela deve responder em:

```bash
curl http://127.0.0.1:8080/actuator/health
```

### 6.2 Subir o outbox-publisher

Em outro terminal:

```bash
./gradlew :outbox-publisher:bootRun
```

### 6.3 Subir projection-worker

Em outro terminal:

```bash
./gradlew :projection-worker:bootRun
```

### 6.4 Subir metrics-worker

Em outro terminal:

```bash
./gradlew :metrics-worker:bootRun
```

### 6.5 Subir realtime-gateway

Em outro terminal:

```bash
./gradlew :realtime-gateway:bootRun
```

O gateway deve responder em:

```bash
curl http://127.0.0.1:9000/events/health
```

> [!TIP]
> Em desenvolvimento, subir cada módulo em um terminal separado ajuda muito a enxergar falhas de startup, fila inexistente, problema de banco, erro de credencial e ordem de inicialização.

---

## 7. Build rápido para validar módulos

Se você quiser só confirmar que um módulo compila e empacota:

```bash
./gradlew :api-core:bootJar -x test
./gradlew :outbox-publisher:bootJar -x test
./gradlew :projection-worker:bootJar -x test
./gradlew :metrics-worker:bootJar -x test
./gradlew :realtime-gateway:bootJar -x test
```

Isso é útil antes de abrir PR ou disparar deploy.

---

## 8. Checklist de debug local

Quando algo não sobe localmente, verifique nesta ordem:

1. `java -version` está em 21
2. `.env` existe e tem credenciais válidas
3. RabbitMQ está `healthy`
4. O banco aceita conexão com as credenciais informadas
5. A API principal sobe antes dos workers mais dependentes
6. As portas `8080` e `9000` estão livres

Comandos úteis:

```bash
docker compose ps
docker logs -f back-api-kyarem-rabbitmq
./gradlew :api-core:bootRun --stacktrace
./gradlew :projection-worker:bootRun --stacktrace
```

---

## 9. Como debugar em produção na VPS

Entre via SSH na VPS:

```bash
ssh root@SEU_IP_DA_VPS
```

Depois vá para a pasta do deploy:

```bash
cd /root/deploy/kyarem
```

Se sua secret `VPS_DEPLOY_PATH` apontar para outro local, use esse caminho.

### 9.1 Ver estado geral da stack

```bash
docker compose ps
docker ps
```

### 9.2 Ver reinícios e falhas

```bash
docker inspect --format='{{.Name}} restart={{.RestartCount}} status={{.State.Status}} started={{.State.StartedAt}} finished={{.State.FinishedAt}} error={{.State.Error}}' \
  back-api-kyarem-api-core \
  back-api-kyarem-outbox-publisher \
  back-api-kyarem-projection-worker \
  back-api-kyarem-metrics-worker \
  back-api-kyarem-realtime-gateway \
  back-api-kyarem-rabbitmq
```

Se `RestartCount` estiver subindo, o container está em ciclo de falha.

### 9.3 Ver logs por serviço

```bash
docker logs --tail 200 back-api-kyarem-api-core
docker logs --tail 200 back-api-kyarem-outbox-publisher
docker logs --tail 200 back-api-kyarem-projection-worker
docker logs --tail 200 back-api-kyarem-metrics-worker
docker logs --tail 200 back-api-kyarem-realtime-gateway
docker logs --tail 200 back-api-kyarem-rabbitmq
```

Para acompanhar em tempo real:

```bash
docker logs -f back-api-kyarem-api-core
```

### 9.4 Testar healthchecks e portas locais

Na própria VPS:

```bash
curl -fsS http://127.0.0.1:8083/actuator/health
curl -fsS http://127.0.0.1:8084/events/health
```

Se a API principal não responder em `8083`, o problema está antes do Nginx.

Se o SSE não responder em `8084`, o problema está no `realtime-gateway` ou no bind local.

### 9.5 Inspecionar variáveis do container

```bash
docker inspect back-api-kyarem-api-core
docker inspect back-api-kyarem-projection-worker
```

Para focar no ambiente:

```bash
docker inspect --format='{{range .Config.Env}}{{println .}}{{end}}' back-api-kyarem-api-core
```

Use isso para conferir:

- `DB_URL`
- `DB_USER`
- `RABBITMQ_HOST`
- `RABBITMQ_USER`
- `RABBITMQ_VHOST`
- `IMAGE_TAG`
- `GITHUB_REPOSITORY`

### 9.6 Validar o `.env` do deploy

```bash
cat .env
```

Confira se:

- o `IMAGE_TAG` bate com o SHA esperado
- `GITHUB_REPOSITORY` está correto
- credenciais do banco e RabbitMQ não estão vazias

### 9.7 Validar conectividade interna entre containers

Entre em um container:

```bash
docker exec -it back-api-kyarem-api-core /bin/sh
```

Lá dentro, você pode tentar resolver o host interno do RabbitMQ:

```sh
getent hosts back-api-kyarem-rabbitmq
```

Se a imagem tiver utilitários de rede, também pode testar a porta 5672.

---

## 10. Como reconhecer os problemas mais comuns em produção

### 10.1 Container sobe e reinicia em segundos

Causas comuns:

- variável obrigatória ausente no `.env`
- banco recusando conexão
- fila RabbitMQ inexistente
- porta errada
- exceção no startup do Spring

Primeiros comandos:

```bash
docker inspect --format='{{.State.ExitCode}} {{.State.Error}}' back-api-kyarem-projection-worker
docker logs --tail 200 back-api-kyarem-projection-worker
```

### 10.2 RabbitMQ saudável, mas consumidor falha

Geralmente indica:

- fila não declarada
- credencial errada
- vhost incorreto
- listener falhando na inicialização

Cheque:

```bash
docker logs --tail 200 back-api-kyarem-metrics-worker
docker logs --tail 200 back-api-kyarem-realtime-gateway
```

### 10.3 API sobe, mas domínio externo falha

Se `curl http://127.0.0.1:8083/actuator/health` responde, mas o domínio não:

- verifique Nginx
- verifique DNS
- verifique SSL
- verifique firewall

Comandos úteis:

```bash
sudo nginx -t
sudo systemctl status nginx
sudo systemctl reload nginx
```

### 10.4 SSE não entrega eventos

Verifique:

1. `realtime-gateway` está de pé
2. `curl http://127.0.0.1:8084/events/health` responde
3. Nginx tem `proxy_buffering off` para `/events/`
4. O `outbox-publisher` está publicando eventos
5. O `realtime.notify` está sendo criado e consumido

---

## 11. Reiniciar com segurança

Para recarregar a stack após ajuste de `.env` ou compose:

```bash
docker compose up -d --remove-orphans
```

Para reiniciar só um serviço:

```bash
docker restart back-api-kyarem-realtime-gateway
```

Para derrubar e subir de novo:

```bash
docker compose down
docker compose up -d
```

> [!WARNING]
> Evite `docker compose down -v` em produção sem certeza total, porque isso pode apagar volumes associados, incluindo dados persistidos do RabbitMQ.

---

## 12. Fluxo recomendado para desenvolver com segurança

Um fluxo saudável para novas features e debug é:

1. Ajustar `.env` local
2. Subir RabbitMQ local
3. Rodar `api-core`
4. Rodar os workers/gateway em terminais separados
5. Validar health endpoints
6. Fazer `bootJar` dos módulos alterados
7. Só depois mandar deploy

Esse fluxo reduz muito o risco de descobrir erro apenas na VPS.

---

## 13. Comandos de bolso

### Desenvolvimento local

```bash
docker compose up -d back-api-kyarem-rabbitmq
./gradlew :api-core:bootRun
./gradlew :outbox-publisher:bootRun
./gradlew :projection-worker:bootRun
./gradlew :metrics-worker:bootRun
./gradlew :realtime-gateway:bootRun
```

### Produção

```bash
docker compose ps
docker logs --tail 200 back-api-kyarem-api-core
docker logs --tail 200 back-api-kyarem-realtime-gateway
curl -fsS http://127.0.0.1:8083/actuator/health
curl -fsS http://127.0.0.1:8084/events/health
```

---

## 14. Conclusão

Para trabalhar bem nesse backend, a resposta curta é:

- **Sim, instale Java 21**
- use Docker para o RabbitMQ local
- rode os módulos Spring separadamente durante o desenvolvimento
- use `docker inspect`, `docker logs` e `curl` como trio principal de debug em produção

Com isso, você passa a ter um ambiente muito mais previsível para desenvolver, testar e investigar falhas sem depender só do deploy.
