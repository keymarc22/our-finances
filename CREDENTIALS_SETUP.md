# Configuración de Credentials (Credenciales)

Este documento explica qué configuración necesitas agregar en los credentials de Rails para que la aplicación funcione correctamente.

## ¿Qué son los Credentials?

Rails usa un sistema de credenciales encriptadas para almacenar información sensible como claves API, URLs de bases de datos, etc. Los credentials se guardan en archivos encriptados y se descifran usando una master key.

## Configuración de Redis

La aplicación usa **Sidekiq** para procesar trabajos en segundo plano (background jobs), y Sidekiq requiere una conexión a Redis.

### Para Desarrollo (Development)

Edita tus credentials de desarrollo:

```bash
EDITOR="code --wait" bin/rails credentials:edit --environment development
```

Agrega la siguiente configuración:

```yaml
redis_url: redis://localhost:6379/1

# Otras configuraciones necesarias...
data_retention:
  months: 6
```

### Para Producción (Production)

Edita tus credentials de producción:

```bash
EDITOR="code --wait" bin/rails credentials:edit --environment production
```

Agrega la siguiente configuración:

```yaml
redis_url: redis://tu-servidor-redis:6379/0
# O si usas un servicio como Redis Cloud, Heroku Redis, etc:
# redis_url: rediss://usuario:password@host:puerto/0

# Configuración de retención de datos
data_retention:
  months: 6

# Otras credenciales de producción...
```

### Para Testing (CI)

En el ambiente de testing, la aplicación usa un valor por defecto (`redis://localhost:6379/0`) si no hay credentials configurados. Esto permite que los tests funcionen en CI sin necesidad de configurar credentials.

Si necesitas usar credentials específicos para testing:

```bash
EDITOR="code --wait" bin/rails credentials:edit --environment test
```

```yaml
redis_url: redis://localhost:6379/0

data_retention:
  months: 6
```

## Configuración Completa de Ejemplo

Aquí está un ejemplo completo de lo que deberías tener en tus credentials:

### Development

```yaml
# config/credentials/development.yml.enc
redis_url: redis://localhost:6379/1

data_retention:
  months: 6

# Agrega aquí otras configuraciones de desarrollo
# como claves de API para servicios externos, etc.
```

### Production

```yaml
# config/credentials/production.yml.enc
redis_url: rediss://usuario:password@redis-server.com:6379/0

data_retention:
  months: 12

# Cloudinary (si usas almacenamiento de archivos)
cloudinary:
  cloud_name: tu_cloud_name
  api_key: tu_api_key
  api_secret: tu_api_secret

# Mailgun (si usas envío de emails)
mailgun:
  api_key: tu_mailgun_api_key
  domain: tu_dominio.com
```

## Cómo instalar Redis localmente

### macOS
```bash
brew install redis
brew services start redis
```

### Ubuntu/Debian
```bash
sudo apt-get install redis-server
sudo systemctl start redis-server
```

### Windows
Descarga Redis desde: https://redis.io/download o usa WSL2

### Docker
```bash
docker run -d -p 6379:6379 redis:7.0
```

## Verificar la conexión a Redis

Puedes verificar que Redis está funcionando:

```bash
redis-cli ping
# Debería responder: PONG
```

## Troubleshooting

### Error: "No credentials found"
- Asegúrate de haber ejecutado `bin/rails credentials:edit` para crear el archivo
- Verifica que existe el archivo `config/master.key` o la variable de ambiente `RAILS_MASTER_KEY`

### Error: "Connection refused to Redis"
- Verifica que Redis está corriendo: `redis-cli ping`
- Verifica la URL en tus credentials
- Revisa el puerto (por defecto es 6379)

### Error en CI: "Redis connection failed"
- El CI ya está configurado con un servicio de Redis
- No necesitas configurar credentials para el ambiente de testing
- Si persiste el error, revisa los logs del workflow de GitHub Actions

## Más Información

- [Guía de Credentials de Rails](https://guides.rubyonrails.org/security.html#custom-credentials)
- [Documentación de Sidekiq](https://github.com/mperham/sidekiq/wiki)
- [Documentación de Redis](https://redis.io/documentation)
