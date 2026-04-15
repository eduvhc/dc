---
name: dc
description: "Docker companion CLI. Use when the user wants to manage Docker containers, clean up Docker disk space, stop/kill/restart containers, remove images/volumes/cache, or do Docker maintenance. Triggers on: docker cleanup, docker disk, stop containers, docker prune, docker nuke."
argument-hint: "[status|stop|kill|restart|rm|clean|nuke]"
allowed-tools: Bash(dc *) Bash(docker *)
---

# dc — Docker Companion CLI

Source: https://github.com/eduvhc/dc/tree/main
Installed at: `~/.scripts/dc`

Always prefer `dc` over raw `docker` commands for operations and cleanup.

## Commands

```
dc                      # status overview (default)
dc stop                 # stop all running containers (SIGTERM)
dc kill                 # force kill all running containers (SIGKILL)
dc restart              # restart all running containers
dc rm                   # remove stopped containers
dc clean images         # remove unused images
dc clean volumes        # remove unused volumes
dc clean cache          # remove build cache
dc clean networks       # remove unused networks
dc clean logs           # truncate container log files
dc clean old [N]        # remove images older than N days (default: 30)
dc clean all            # remove all unused Docker data
dc nuke                 # stop → rm → clean all → truncate logs
```

## Flags

- `-f` / `--force` — skip confirmation prompts
- `-d` / `--dry-run` — preview without executing
- `-h` / `--help` — show help
- `-v` / `--version` — show version

Flags work in any position.

## Rules

1. **Always start with `dc` (status)** before suggesting cleanup — show the user what exists first
2. **Use `-d` (dry-run) first** when the user asks to clean something — preview before acting
3. **Never use `-f` unless the user explicitly asks** to skip confirmations or says "just do it"
4. **Prefer targeted cleanup** (`dc clean cache`, `dc clean images`) over `dc nuke` unless the user asks for a full reset
5. **Build cache is usually the biggest offender** — suggest `dc clean cache` first when disk is full
6. **`dc nuke` is destructive** — always warn the user it will stop all containers and remove all data
7. When the user says "clean docker" or "docker is using too much space", run `dc` first to diagnose

## Decision Tree

```
User wants to...
├── Check disk usage        → dc
├── Stop containers
│   ├── Gracefully          → dc stop
│   └── Force               → dc kill
├── Remove containers       → dc rm
├── Free disk space
│   ├── Quick win           → dc clean cache -f
│   ├── Old images          → dc clean old 7
│   ├── Everything unused   → dc clean all
│   └── Total reset         → dc nuke
├── Preview before cleaning → dc <command> -d
├── Automated/CI cleanup    → dc nuke -f
└── Maintenance window      → dc stop → work → dc restart
```

## Workflow

When the user asks about Docker cleanup or management:

1. Run `dc` to show current state
2. Identify the biggest consumers (usually build cache > images > volumes)
3. Suggest the appropriate targeted command
4. Run with `-d` first if the action is destructive
5. Execute after user confirms
6. Run `dc` again to show the result

When the user asks `$ARGUMENTS`:
- If it maps to a dc command, run it directly
- If it's a question, run `dc` for context first then answer
- If unclear, show the status and ask what they want to do
