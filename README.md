# ROS2 Systemd Manager

ROS2 Systemd Manager is a YAML-driven tool to manage ROS2 launch tasks as systemd services.

## What It Does

- Bootstrap local files with `ros2-systemd-manager init`
- Install units with `install`
- Install + start + enable with `apply`
- Remove units with `uninstall`
- Run synchronized update flow with stale-unit cleanup via `update`
- Regenerate Makefile only with `makefile`

## CLI

`ros2-systemd-manager [action] [--config PATH] [--workspace-key KEY] [--previous-makefile PATH]`

Supported actions:

- `init`
- `install`
- `apply`
- `uninstall`
- `update`
- `makefile`

## Init Output

Run in an empty directory:

```bash
ros2-systemd-manager init
```

Generated files:

- `./ros2_services.yaml`
- `./Makefile`

## YAML Keys

Required:

- `systemd`
- `runtime`
- `workspaces`

Optional:

- `actions` (default action is `apply`)
- `makefile`

## Generated Makefile

Primary targets:

- `make install`
- `make apply`
- `make uninstall`
- `make update`
- `make makefile`
- `make start|stop|restart|status|enable|disable`
- `make logs` / `make logs-recent`
- `make <op>-<service>` (op in start/stop/restart/status/enable/disable/logs/logs-recent)

Config behavior:

- No hardcoded absolute config path.
- Auto-discovery in current directory: `./ros2_services.yaml`, then first `./*.yaml`.
- Override manually:

```bash
make apply CONFIG=./my_services.yaml
```

## Safety

- Use trusted launch commands only.
- Validate workspace paths and setup scripts before `apply` or `update`.
- Prefer `install` first for new services.
