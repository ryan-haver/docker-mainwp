# MainWP Docker Stack

This project packages the MainWP Dashboard alongside the latest WordPress image so you can spin up a fully isolated management instance with a single command. The container automatically installs and activates the MainWP plugin (plus any additional plugins you list) once WordPress is configured.

## What's inside?

- **Custom WordPress image** based on `wordpress:6.6.2-php8.2-apache`.
- **WP-CLI baked in** for scripting installs, updates, and maintenance.
- **Bootstrap helper** that waits for `wp core is-installed` and then installs MainWP Dashboard (and optional extra plugins) automatically.
- **docker-compose stack** with MariaDB 11.4, persistent volumes, and sensible defaults for local experimentation.
- **Standalone Dockerfile** for situations where you only need the MainWP-ready WordPress image and will point it at an existing database.
- **Version pinning support** via the `WORDPRESS_TAG` build argument so you can stay on specific WordPress/PHP combinations or bump to the latest tag with an env override.

## Deployment options

### docker compose stack (WordPress + MariaDB)

#### Getting started

- **Step 1:** Copy or rename `docker-compose.yml` as needed.
- **Step 2:** Launch the stack:

  ```bash
  docker compose up --build -d
  ```

- **Step 3:** Complete the WordPress installer by visiting [http://localhost:8080](http://localhost:8080) after the containers are healthy. Once you finish the WordPress setup wizard, the bootstrap helper automatically installs and activates the MainWP plugin.
- **Step 4:** Log in and start configuring MainWP.

This path is ideal for local development or a full-stack lab because the compose file provisions both WordPress and MariaDB services with persistent volumes (`wp_data`, `db_data`).

### Standalone Dockerfile (external database)

If you already have a managed database (e.g., RDS, Azure MySQL, on-prem server) you can build a lean container with `Dockerfile.standalone`:

- **Step 1:** Build the image:

  ```bash
  docker build -f Dockerfile.standalone -t mainwp-standalone .
  ```

- **Step 2:** Prepare an env file (e.g., `mainwp.env`) containing at least the WordPress DB settings (see table below).
- **Step 3:** Run the container:

    ```bash
    docker run -d \
      --name mainwp \
      --env-file mainwp.env \
      -p 8080:80 \
      -v mainwp_data:/var/www/html \
      mainwp-standalone
    ```

Use Docker secrets/Kubernetes secrets for production deployments. The standalone image shares the same entrypoint/bootstrap logic as the compose stack, so MainWP installs automatically once WordPress is configured.

Example `mainwp.env`:

```env
WORDPRESS_DB_HOST=db.example.com:3306
WORDPRESS_DB_NAME=mainwp
WORDPRESS_DB_USER=mainwp
WORDPRESS_DB_PASSWORD=change-me
MAINWP_EXTRA_PLUGINS="mainwp-child"
```

## Configuration

### Runtime environment variables

The containers honor the same environment variables supported by the official WordPress image plus a few MainWP-specific toggles. Set them in `docker-compose.yml`, a `.env` file, or the `docker run` command line.

| Variable | Description | Default |
| --- | --- | --- |
| `WORDPRESS_DB_HOST` | Database host (and optional port). | `db:3306` in compose |
| `WORDPRESS_DB_USER` / `WORDPRESS_DB_PASSWORD` / `WORDPRESS_DB_NAME` | Database credentials. | `mainwp` (compose) |
| `WORDPRESS_TABLE_PREFIX` | Optional table prefix. | `wp_` |
| `WORDPRESS_CONFIG_EXTRA` | Extra PHP constants injected into `wp-config.php`. | Adds `FS_METHOD` and child auto-updates |
| `MAINWP_AUTO_INSTALL` | Set to `false` to skip automatic MainWP installation. | `true` |
| `MAINWP_EXTRA_PLUGINS` | Space-separated list of plugin slugs to auto-install/activate alongside MainWP (e.g., `mainwp-child updraftplus`). | _empty_ |
| `MAINWP_MAX_RETRIES` | How many times the bootstrap script checks for a completed WP install. | `30` |
| `MAINWP_RETRY_INTERVAL` | Seconds between retries. | `10` |
| `WORDPRESS_PATH` | Path WP-CLI should use (only needed if you change the document root). | `/var/www/html` |

Refer to the [official WordPress image docs](https://hub.docker.com/_/wordpress) for additional variables such as `WORDPRESS_DEBUG`, `WORDPRESS_CONFIG_EXTRA`, and SMTP-related settings—they all work here too.

**Database options:**

- Use the bundled MariaDB service (default) when running `docker compose up` locally.
- For cloud or production environments, set `WORDPRESS_DB_HOST`, `WORDPRESS_DB_USER`, `WORDPRESS_DB_PASSWORD`, and `WORDPRESS_DB_NAME` to point at your managed MySQL/MariaDB instance. The image already includes `mariadb-client`, so WP-CLI commands (and the bootstrapper) can talk to remote databases without extra tooling.

### Build-time controls

| Build argument | Where to set it | Purpose | Default |
| --- | --- | --- | --- |
| `WORDPRESS_TAG` | `docker-compose.yml` (`build.args`) or `docker build --build-arg WORDPRESS_TAG=...` | Chooses the upstream WordPress image tag (e.g., `6.6.2-php8.3-fpm`, `latest`). | `6.6.2-php8.2-apache` |

- When using docker compose, create a `.env` file and add `WORDPRESS_TAG=6.6.3-php8.2-apache` (or any official tag). Compose injects that value into the build arg automatically thanks to `${WORDPRESS_TAG:-...}` in the file.
- For the standalone Dockerfile, pass `--build-arg WORDPRESS_TAG=latest` during `docker build` to pin or track specific versions.

## Continuous builds

The workflow at `.github/workflows/auto-build.yml` checks the official WordPress release feed every morning (06:30 UTC). When it detects a new core version it:

- Builds this image with `WORDPRESS_TAG=<version>-php8.2-apache`.
- Publishes the result to GitHub Container Registry (`ghcr.io/<your-account>/wordpress-manager-mainwp:<version>` and the rolling `latest` tag).
- Skips the build entirely if the tag has already been produced, thanks to a simple cache marker stored in the repository workspace.

You can also trigger the workflow on demand from the Actions tab (look for **Build Latest WordPress Image**). If you prefer Docker Hub, add `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN` secrets and extend the workflow to log in to that registry as well.

## Useful commands

- **View logs:** `docker compose logs -f mainwp`
- **Run WP-CLI:**

  ```bash
  docker compose exec mainwp wp plugin list --allow-root
  ```

- **Stop stack:** `docker compose down`
- **Remove volumes (reset data):** `docker compose down -v`

## Next steps

- Adjust `docker-compose.yml` (ports, volumes, secrets) before deploying to shared environments.
- Once you're satisfied, initialize a new Git repository (e.g., on GitHub) and push this codebase as your canonical MainWP container source.
