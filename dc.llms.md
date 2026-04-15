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

| Scenario | Command |
|----------|---------|
| "How much disk is Docker using?" | `dc` |
| "Stop everything for maintenance" | `dc stop` |
| "Container won't stop" | `dc kill` |
| "Clean up after dev session" | `dc clean all` |
| "Total reset, fresh start" | `dc nuke` |
| "Disk is full, need space NOW" | `dc nuke -f` |
| "Clean old CI images" | `dc clean old 7 -f` |
| "Logs eating disk" | `dc clean logs` |
| "What would cleanup remove?" | `dc nuke -d` |
