# Couple Finances

Shared Finances es una aplicación para gestionar y organizar las finanzas en grupo.
![image](https://github.com/user-attachments/assets/44f84b24-eefd-453b-b222-c958db46d2eb)


## Requisitos

- **Ruby version:** 3.3.1
- **Rails version:** 8.0.2
- **Base de datos:** PostgreSQL
- **Redis:** Para procesamiento de trabajos en segundo plano (Sidekiq)

## Instalación

1. Clona el repositorio:

  ```bash
  git clone https://github.com/tu-usuario/couple-finances.git
  cd couple-finances
  ```

2. Instala las dependencias:

  ```bash
  bundle install
  rails tailwindcss:build
  ```

3. **Instala y configura Redis:**

  ```bash
  # macOS
  brew install redis
  brew services start redis

  # Ubuntu/Debian
  sudo apt-get install redis-server
  sudo systemctl start redis-server

  # O usando Docker
  docker run -d -p 6379:6379 redis:7.0
  ```

4. **Configura las credenciales** (incluyendo Redis URL):

  Ver [CREDENTIALS_SETUP.md](CREDENTIALS_SETUP.md) para instrucciones detalladas.

  ```bash
  EDITOR="code --wait" bin/rails credentials:edit --environment development
  ```

  Agrega al menos:
  ```yaml
  redis_url: redis://localhost:6379/1
  data_retention:
    months: 6
  ```

## Creación e inicialización de la base de datos

```bash
rails db:create
rails db:migrate
rails db:seed
```

## Ejecución de la aplicación

```bash
rails server
```

Accede a [http://localhost:3000](http://localhost:3000) en tu navegador.

## Pruebas

Para ejecutar la suite de tests:

```bash
bundle exec rspec
```

¡Contribuciones y sugerencias son bienvenidas!
