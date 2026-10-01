*This project has been created as part of the 42 curriculum by rgoossen.*

# Inception

## Description

Inception is a system-administration project that teaches containerisation by building a small but complete web infrastructure from scratch using Docker Compose.

**Goal:** Run a WordPress website served over HTTPS, backed by a MariaDB database, behind an NGINX reverse proxy — each in its own container, all wired together with a private Docker network and persistent volumes.

```
Internet
   │  (port 443 only)
   ▼
┌─────────────────────────── Docker network ───────────────────────────────┐
│  Container NGINX  ──(FastCGI:9000)──►  Container WordPress+PHP-FPM       │
│        │                                        │                        │
│        │                              ◄──(3306)── Container MariaDB      │
│        ▼                                        ▼                        │
│  Volume: wordpress_files          Volume: wordpress_files   Volume: db_data │
└────────────────────────────────────────────────────────────────────────── ┘
                                                  ▼
                                    /home/login/data/{wordpress,mariadb}
```

Three containers, two volumes, one network, zero pre-built images (only base Alpine).

---

## Instructions

### Prerequisites

- Docker Engine and Docker Compose v2
- Running inside a Virtual Machine (required by the subject)
- Internet access for the first build (downloads WordPress core and WP-CLI)

### 1. Configure your login

Edit `srcs/.env` and replace every occurrence of `rgoossen` with your actual 42 login.

### 2. Set real passwords

Edit the three files in `secrets/`:

| File | Contains |
|------|----------|
| `secrets/db_password.txt` | MySQL password for the `wpuser` account |
| `secrets/db_root_password.txt` | MySQL root password |
| `secrets/credentials.txt` | Line 1: WordPress admin password, Line 2: editor password |

Choose strong passwords. These files are **not pushed to a public repo**.

### 3. Add your domain to `/etc/hosts`

```bash
echo "127.0.0.1 rgoossen.42.fr" | sudo tee -a /etc/hosts
```

### 4. Build and start

```bash
make
```

`make` creates the data directories, builds all images, and starts the stack.

### 5. Visit the site

Open `https://rgoossen.42.fr` in your browser. Accept the self-signed certificate warning.

### Common commands

```bash
make logs      # Follow all container logs
make ps        # Show container status
make down      # Stop containers (data is preserved)
make clean     # Stop and remove images
make fclean    # Nuclear option — stops, removes images, volumes, and data dirs
make re        # fclean then all
```

---

## Project Description

### Docker in this project

This project uses three custom Docker images built from `alpine:3.20` (penultimate stable — verify the current penultimate at https://alpinelinux.org/releases/ before submitting):

| Image | Service | Key packages |
|-------|---------|--------------|
| `nginx` | Reverse proxy, TLS termination | `nginx`, `openssl` |
| `wordpress` | PHP application + FastCGI | `php82-fpm`, WP-CLI |
| `mariadb` | Database | `mariadb` |

Each `Dockerfile` lives at `srcs/requirements/<service>/Dockerfile`. The Makefile calls `docker compose up --build` which reads `srcs/docker-compose.yml`.

**No ready-made application images are pulled.** Only the base Alpine OS image comes from a registry. Everything else is installed and configured by our own Dockerfiles and entrypoint scripts.

---

## Design Choices — Key Comparisons

### Virtual Machines vs Docker

| Aspect | Virtual Machine | Docker Container |
|--------|-----------------|-----------------|
| Isolation | Full OS — separate kernel | Shares host kernel via namespaces/cgroups |
| Size | GBs (full OS + apps) | MBs (only app + minimal libs) |
| Boot time | Minutes | Milliseconds |
| Overhead | High (hardware emulation) | Near-zero (processes on the host kernel) |
| Use case | Strong isolation, different kernels | Packaging and running services fast |

**Why Docker here?** We want lightweight, reproducible service definitions. Each container is "just" an isolated process group sharing the host kernel — not a full OS. This is why containers must run a real foreground process (PID 1 matters) rather than a looping shell.

**Key insight:** A container is not a mini-VM. It is a process. The kernel is shared. `tail -f`, `sleep infinity`, or `bash` as PID 1 are hacks — if your real service crashes, the container stays "running" but dead. Always `exec` your real service so it becomes PID 1 and receives signals properly.

---

### Secrets vs Environment Variables

| | Environment Variables | Docker Secrets |
|--|-----------------------|----------------|
| Stored in | `.env` file, docker-compose | Files at `secrets/` mounted at `/run/secrets/` |
| Visible in | `docker inspect`, child processes | Only inside the container, as a file |
| Committed to git? | Non-sensitive ones, yes | Never (real passwords) |
| Best for | Config (domain name, db name) | Passwords, API keys, credentials |

**Why both?** Non-sensitive config (domain name, database name, usernames) goes in `.env` because it is handy and non-secret. Passwords go in Docker secrets because they appear nowhere in environment variables or image layers — only inside the running container.

**This project:** `.env` holds domain name and usernames. `secrets/*.txt` hold passwords. The setup scripts read passwords from `/run/secrets/` files, never from env vars.

---

### Docker Network vs Host Network

| | Docker bridge network | Host network (`network: host`) |
|--|----------------------|-------------------------------|
| Isolation | Containers get their own IP space | Container shares host's network stack |
| Container DNS | Containers resolve each other by **service name** | N/A — use `localhost` |
| Port conflicts | No conflict with host ports | Shares all host ports |
| Security | Containers are isolated from host | Container can reach any host service |
| Subject allowed? | Yes ✓ | No — explicitly forbidden |

**Why a bridge network?** The three containers need to talk to each other (NGINX → WordPress → MariaDB) but should not be reachable from the outside except through the published port 443. A bridge network gives each container a name-based DNS entry (e.g., `wordpress`, `mariadb`) so services find each other without hardcoding IPs.

**Critical rule:** `network: host` and `--link` are both forbidden. The `networks:` key must appear in `docker-compose.yml`.

---

### Docker Volumes vs Bind Mounts

| | Named Volumes | Bind Mounts |
|--|---------------|-------------|
| Defined in | `volumes:` section of compose | Inline in a service's `volumes:` list |
| Host path | Managed by Docker (or custom via driver_opts) | Explicit host path |
| Portability | High — Docker manages the path | Lower — hard-codes host paths |
| Use in this project | Required ✓ | Forbidden ✗ |

**Why named volumes?** The subject explicitly forbids bind mounts for persistent storage. Named volumes are Docker-managed storage objects. This project uses named volumes with `driver_opts` to pin storage to `/home/login/data/` on the host — satisfying both the "named volumes" requirement and the "must store at `/home/login/data`" requirement.

**Two volumes in this project:**
- `wordpress_files` → WordPress PHP files, themes, plugins — shared by the `wordpress` and `nginx` containers
- `db_data` → MariaDB data files — only the `mariadb` container

Data persists across `make down` / `make up`. Only `make fclean` removes it.

---

## Resources

### Documentation

- Docker Overview: https://docs.docker.com/get-started/overview/
- Dockerfile best practices: https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
- Docker Compose reference: https://docs.docker.com/compose/compose-file/
- Docker Secrets (Compose): https://docs.docker.com/compose/use-secrets/
- NGINX docs: https://nginx.org/en/docs/
- MariaDB knowledge base: https://mariadb.com/kb/en/
- WP-CLI commands: https://developer.wordpress.org/cli/commands/
- Alpine Linux packages: https://pkgs.alpinelinux.org/packages
- PHP-FPM configuration: https://www.php.net/manual/en/install.fpm.configuration.php
- Understanding PID 1 in Docker: https://cloud.google.com/architecture/best-practices-for-building-containers#signal-handling

### Tutorials / Articles

- "Docker for beginners" — Play With Docker: https://training.play-with-docker.com/
- "How to Dockerize a WordPress site": many resources on the WordPress developer blog
- TLS/SSL basics and self-signed certificates with openssl

### AI usage

Claude (claude-sonnet-4-6) was used for:
- Generating the initial scaffold for all Dockerfiles, docker-compose.yml, Makefile, and entrypoint scripts
- Drafting the conceptual explanations in README.md, USER_DOC.md, and DEV_DOC.md

All generated code was reviewed, understood, and adapted. The student is responsible for being able to explain every line during peer evaluation.
