# Resumen: ¿Qué agregar en los Credentials?

## Para Desarrollo (Local)

Ejecuta:
```bash
EDITOR="code --wait" bin/rails credentials:edit --environment development
```

Agrega esto:
```yaml
redis_url: redis://localhost:6379/1

data_retention:
  months: 6
```

## Para Producción

Ejecuta:
```bash
EDITOR="code --wait" bin/rails credentials:edit --environment production
```

Agrega esto (ajusta la URL según tu servidor Redis):
```yaml
redis_url: redis://tu-servidor-redis:6379/0

data_retention:
  months: 12
```

Si usas un servicio Redis en la nube (como Heroku Redis, Redis Cloud, etc.), la URL será algo como:
```yaml
redis_url: rediss://usuario:password@host.com:puerto/0
```

## Para Testing/CI

**¡No necesitas agregar nada!** El CI ya está configurado automáticamente.

Si quieres configurarlo manualmente:
```bash
EDITOR="code --wait" bin/rails credentials:edit --environment test
```

```yaml
redis_url: redis://localhost:6379/0

data_retention:
  months: 6
```

## Verificar que Redis está corriendo

```bash
# Instalar Redis (si no lo tienes)
# macOS:
brew install redis
brew services start redis

# Ubuntu/Debian:
sudo apt-get install redis-server

# Verificar que funciona:
redis-cli ping
# Debe responder: PONG
```

## Más detalles

Ver [CREDENTIALS_SETUP.md](CREDENTIALS_SETUP.md) para instrucciones completas y troubleshooting.
