# vps 💾

## Provision the instance

Copy the example environment file and modify the `VPS Provisioning` configs.

```sh
cp .env.example .env
```

#### One-time setup

```sh
make bootstrap
```

- Generate an SSH key pair
- Create the main user
- Set up firewall rules
- Change the root password
- Disable root login

#### Idempotent provisioning steps

```sh
make provision
```

- Install: virtualenv, Docker, AWS CLI
- Allow 80/TCP connections

## Run shared services

Update the `Docker Services` configs in `.env`, where `ENVIRONMENT` can be `dev` (local machine) or `prod`.

```sh
make start
```

- Create the `tifa` network
- Run the Traefik reverse proxy
- Run a MySQL instance
- Run a phpMyAdmin instance

In the development environment, a certificate is created at `./assets/traefik/certs/dev.crt` and is added to the system's trusted SSL certificates (this is currently only configured to work in macOS).

## Add a new service

### In this repo

Add a new hostname in the `.env` file and restart services.

```sh
make restart
```

### In that service

Add the following labels and `proxy` network to service:

```yaml
  myservice:
    image: myimage
    labels:
      traefik.enable: true
      traefik.http.routers.<ROUTER_KEY>.rule: Host(`${HOSTNAME:-}`)
      traefik.http.routers.<ROUTER_KEY>.entrypoints: <ENTRYPOINT>
    networks:
      - tifa
```

Each service needs to have a unique `ROUTER_KEY`.

Currently supported entrypoints:

Entrypoint | Port
--- | ---
web | 80
websecure | 443
mysql | 3306

For `websecure` HTTPS connections, enable TLS.

```yaml
      traefik.http.routers.<ROUTER_KEY>.tls.certresolver: letsencrypt
```

Finally, define the external network at the top level.

```yaml
networks:
  proxy:
    external: true
```
