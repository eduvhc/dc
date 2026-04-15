# dc — Docker Companion CLI

A fast, opinionated Docker cleanup and operations tool. Single bash script, no dependencies, works on macOS and Linux.

Born out of frustration with Docker silently eating 50GB+ of disk space on a homelab Mac.

## Why

Docker accumulates garbage fast — dangling images, stopped containers, orphaned volumes, build cache that never gets invalidated, and log files that grow forever. The native `docker system prune` exists but it's limited:

- Doesn't touch build cache by default
- Doesn't truncate logs
- Doesn't stop running containers first
- No dry-run mode
- No way to clean images by age

`dc` wraps all of that into a single tool with sane defaults, confirmation prompts, and colored output.

## Install

```bash
# Clone or copy the script
curl -o ~/.local/bin/dc https://raw.githubusercontent.com/eduvhc/homelab/main/scripts/dc
chmod +x ~/.local/bin/dc

# Or clone the repo and symlink
git clone https://github.com/eduvhc/homelab.git
ln -s $(pwd)/homelab/scripts/dc ~/.local/bin/dc
```

Make sure `~/.local/bin` (or wherever you place it) is in your `PATH`.

## Quick Start

```bash
dc                  # See what Docker is using
dc nuke             # Stop everything + full cleanup (asks first)
dc nuke -f          # Same but no questions asked
```

## Commands

### Status

```bash
dc                  # Full overview: disk, containers, images, volumes, networks
dc status           # Same thing
```

### Operations

Bulk container operations — always shows what will be affected before acting.

```bash
dc stop             # Gracefully stop all running containers
dc kill             # Force kill all running containers
dc restart          # Restart all running containers
dc rm               # Remove stopped containers
```

### Cleanup

Targeted cleanup by resource type.

```bash
dc clean images     # Remove all unused images
dc clean volumes    # Remove unused volumes (lists them first)
dc clean cache      # Remove build cache
dc clean networks   # Remove unused custom networks
dc clean logs       # Truncate all container log files
dc clean old 7      # Remove images older than 7 days
dc clean all        # Remove all unused data at once
```

### Nuke

The nuclear option. Runs the full pipeline in order:

```
stop all containers → remove stopped → prune images, volumes, networks → purge build cache → truncate logs
```

```bash
dc nuke             # With confirmation
dc nuke -f          # No confirmation (CI/cron friendly)
```

## Options

Every command supports these flags:

| Flag | Description |
|------|-------------|
| `-f`, `--force` | Skip all confirmation prompts |
| `-d`, `--dry-run` | Show what would happen without doing anything |
| `-h`, `--help` | Show help |
| `-v`, `--version` | Show version |

Flags can go anywhere — `dc clean all -f` and `dc -f clean all` both work.

### Dry Run

Preview what any command would do before committing:

```bash
dc nuke -d          # Shows full breakdown without touching anything
dc clean images -d  # Lists all images that would be removed
dc stop -d          # Shows which containers would be stopped
```

## Examples

```bash
# Morning routine — check what's eating disk
dc

# Dev reset — stop everything, clean the slate
dc nuke -f

# CI pipeline — clean old images after deploy
dc clean old 7 -f

# Investigate before cleaning
dc clean volumes -d

# Reclaim build cache (often the biggest offender)
dc clean cache

# Cron job — weekly cleanup
# 0 3 * * 0 /path/to/dc nuke -f >> /var/log/dc-cleanup.log 2>&1
```

## Features

- **Single file** — one bash script, copy it anywhere
- **No dependencies** — just bash and docker
- **Cross-platform** — macOS (BSD) and Linux (GNU) compatible
- **Safe by default** — confirmation prompts on every destructive action
- **CI friendly** — `-f` flag for non-interactive environments
- **Dry run** — preview everything before committing
- **Colored output** — auto-disabled when piping or in non-TTY environments
- **Strict mode** — `set -euo pipefail` catches errors early

## Compatibility

| Platform | Status |
|----------|--------|
| macOS (Apple Silicon) | Tested |
| macOS (Intel) | Should work |
| Ubuntu / Debian | Should work |
| Alpine / RHEL | Should work |
| Docker Desktop | Tested |
| OrbStack | Tested |
| Colima | Should work |

Requires: `bash` >= 4.0, `docker` CLI.

## License

MIT — do whatever you want with it.
