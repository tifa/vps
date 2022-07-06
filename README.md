# vps 💾

Provision a VPS.

## Configuration

Copy the example environment file and modify the configs.

```sh
cp .env.example .env
```

## Bootstrap

One-time setup.

```sh
make bootstrap
```

- Generate an SSH key pair
- Create the main user
- Set up firewall rules
- Change the root password
- Disable root login

## Provision

Idempotent provisioning steps.

```sh
make
```

- Install: virtualenv, Docker, AWS CLI
- Allow 80/TCP connections
