# dc — LLM Reference

> Docker companion CLI. Single bash script, no dependencies.

## Quick Reference

```
dc                      # status overview
dc stop                 # stop all running containers
dc kill                 # force kill all running containers
dc restart              # restart all running containers
dc rm                   # remove stopped containers
dc clean images         # remove unused images
dc clean volumes        # remove unused volumes
dc clean cache          # remove build cache
dc clean networks       # remove unused networks
dc clean logs           # truncate container log files
dc clean old [N]        # remove images older than N days (default: 30)
dc clean all            # remove all unused Docker data
dc nuke                 # stop + rm + clean all + truncate logs
```

## Flags

| Flag | Effect |
|------|--------|
| `-f` / `--force` | Skip confirmation prompts |
| `-d` / `--dry-run` | Preview without executing |
| `-h` / `--help` | Show help |
| `-v` / `--version` | Show version |

Flags work in any position: `dc clean all -f` and `dc -f clean all` are equivalent.

## Behavior

- Every destructive command lists affected resources and asks for confirmation before acting
- `-f` suppresses all prompts — safe for scripts and cron
- `-d` runs the full logic but skips all mutations — use to preview
- Colors auto-disable when stdout is not a TTY (piping, redirection)
- Exit codes: `0` success, `1` error, `127` docker not found

## Command Details

### `dc status` (default)

Shows: disk usage (`docker system df`), running/stopped container counts with names, image count with dangling count, volume count with names (top 10), custom network count.

### `dc stop` / `dc kill` / `dc restart`

Operates on ALL running containers. Lists them first. `stop` sends SIGTERM, `kill` sends SIGKILL.

### `dc rm`

Removes containers with status `exited` only. Equivalent to `docker container prune`.

### `dc clean <target>`

- `images` — `docker image prune -a -f` (removes all not used by running containers)
- `volumes` — `docker volume prune -a -f` (lists volume names before deleting)
- `cache` — `docker builder prune --all -f`
- `networks` — `docker network prune -f` (custom networks only)
- `logs` — truncates log files in-place (`: > file`), does not delete them
- `old N` — compares `docker images --format '{{.CreatedAt}}'` against `N` days ago, removes matches with `docker rmi -f`
- `all` — shows before/after `docker system df`, runs `docker system prune -a --volumes -f` + `docker builder prune --all -f`

### `dc nuke`

Pipeline: stop all running → `docker system prune -a --volumes -f` → `docker builder prune --all -f` → truncate all container logs. Single confirmation prompt (or none with `-f`).

## Common Patterns

```bash
# CI: clean after deploy
dc clean old 7 -f

# Dev: full reset
dc nuke -f

# Check what nuke would do
dc nuke -d

# Cron: weekly cleanup
0 3 * * 0 /path/to/dc nuke -f >> /var/log/dc.log 2>&1

# Reclaim disk fast (cache is usually the biggest)
dc clean cache -f

# Stop everything before maintenance
dc stop -f && dc rm -f
```

## When to Use Each Command

### Diagnostics

| Scenario | Command | Why this one |
|----------|---------|-------------|
| Check Docker disk usage | `dc` | Quick overview of all resource types with counts and sizes |
| See what cleanup would free | `dc nuke -d` | Dry run walks through every cleanup step without deleting |
| Preview specific cleanup | `dc clean images -d` | Shows exact images/volumes/etc. that would be removed |
| Check if anything is running | `dc status` | Lists running containers with names, images, and uptime |

### Container Operations

| Scenario | Command | Why this one |
|----------|---------|-------------|
| Stop everything for maintenance | `dc stop` | Graceful SIGTERM — lets containers shut down cleanly |
| Container hanging / won't stop | `dc kill` | SIGKILL — immediate termination, last resort |
| Restart after config change | `dc restart` | Stops and starts all running containers in place |
| Clean up stopped containers | `dc rm` | Removes exited containers only, leaves running ones alone |
| Stop then remove all | `dc stop -f && dc rm -f` | Chain for full container teardown without cleaning images/volumes |

### Cleanup — Targeted

| Scenario | Command | Why this one |
|----------|---------|-------------|
| Disk full, need space fast | `dc clean cache -f` | Build cache is usually the biggest offender (often 10-50GB) |
| Too many old images piling up | `dc clean images` | Removes all images not used by running containers |
| Old CI/CD images after deploy | `dc clean old 7 -f` | Age-based — only removes images older than N days |
| Database volumes from old projects | `dc clean volumes` | Lists volume names before deleting so you can verify |
| Log files growing unbounded | `dc clean logs` | Truncates in-place without removing — containers keep logging |
| Orphaned networks after compose down | `dc clean networks` | Removes custom networks not attached to any container |
| Clean everything unused at once | `dc clean all` | Single command for images + volumes + cache + networks + containers |

### Cleanup — Nuclear

| Scenario | Command | Why this one |
|----------|---------|-------------|
| Full dev environment reset | `dc nuke` | Stops all → removes all → cleans all → truncates logs. One prompt |
| Automated weekly cleanup (cron) | `dc nuke -f` | Same pipeline, no prompts. Safe for non-interactive environments |
| Before switching projects | `dc nuke` | Ensures no port conflicts, stale volumes, or leftover state |
| CI runner disk reclamation | `dc nuke -f` | Runners accumulate garbage fast — run after each pipeline |

### Composition Patterns

| Scenario | Commands | Why |
|----------|----------|-----|
| Careful cleanup | `dc nuke -d` then `dc nuke` | Preview first, then execute |
| Stop but keep images | `dc stop -f && dc rm -f && dc clean cache -f` | Preserves images for faster restarts |
| Clean only dangling | `dc clean images` | Only removes images not referenced by any container |
| Maintenance window | `dc stop -f` → do work → `dc restart -f` | Pause/resume without destroying anything |
| Emergency disk recovery | `dc nuke -f && dc clean logs -f` | Maximum space reclamation, no questions |
