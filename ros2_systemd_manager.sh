#!/usr/bin/env bash
set -euo pipefail

# 管理两个 ROS2 launch 命令对应的 systemd 服务
# 支持模式：
#   install-only           仅安装服务文件（不启动、不自启动）
#   install-start-enable   安装 + 立即启动 + 开机自启动
#   uninstall              卸载（停止、取消自启动、删除服务文件）

MODE=""
WORKSPACE="/home/infantry/infantry_ws"

FOX_SERVICE="ros2-foxglove-bridge.service"
SOEM_SERVICE="ros2-soem-bringup.service"
SYSTEMD_DIR="/etc/systemd/system"

usage() {
  cat <<EOF
用法：sudo $0 [mode] [--ws <workspace_path>]

mode:
  install-only           仅安装
  install-start-enable   安装 + 启动 + 自启动（默认）
  uninstall              卸载

可选参数:
  --ws <workspace_path>  ROS2 工作空间路径（默认：/home/infantry/infantry_ws）

示例：
  sudo $0
  sudo $0 install-only
  sudo $0 install-start-enable
  sudo $0 install-start-enable --ws /home/infantry/infantry_ws
  sudo $0 uninstall
EOF
}

log() {
  echo "[INFO] $*"
}

err() {
  echo "[ERROR] $*" >&2
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "请使用 sudo/root 运行此脚本。"
    exit 1
  fi
}

parse_args() {
  MODE="install-start-enable"

  if [[ $# -gt 0 ]]; then
    case "$1" in
      install-only|install-start-enable|uninstall)
        MODE="$1"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
    esac
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --ws)
        if [[ $# -lt 2 ]]; then
          err "--ws 需要一个路径参数。"
          exit 1
        fi
        WORKSPACE="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        err "未知参数: $1"
        usage
        exit 1
        ;;
    esac
  done

  case "$MODE" in
    install-only|install-start-enable|uninstall)
      ;;
    *)
      err "未知模式: $MODE"
      usage
      exit 1
      ;;
  esac
}

validate_workspace_for_install() {
  if [[ ! -d "$WORKSPACE" ]]; then
    err "工作空间不存在: $WORKSPACE"
    exit 1
  fi
  if [[ ! -f "$WORKSPACE/install/setup.bash" ]]; then
    err "未找到 setup 脚本: $WORKSPACE/install/setup.bash"
    exit 1
  fi
}

write_services() {
  local fox_file="$SYSTEMD_DIR/$FOX_SERVICE"
  local soem_file="$SYSTEMD_DIR/$SOEM_SERVICE"

  cat > "$fox_file" <<EOF
[Unit]
Description=ROS2 Foxglove Bridge
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$WORKSPACE
Environment=HOME=/root
ExecStart=/bin/bash -lc 'source "$WORKSPACE/install/setup.bash" && exec ros2 launch foxglove_bridge foxglove_bridge_launch.xml'
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

  cat > "$soem_file" <<EOF
[Unit]
Description=ROS2 SOEM Bringup
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=$WORKSPACE
Environment=HOME=/root
ExecStart=/bin/bash -lc 'source "$WORKSPACE/install/setup.bash" && exec ros2 launch soem_bringup bringup.launch.py'
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

  chmod 644 "$fox_file" "$soem_file"
}

install_only() {
  validate_workspace_for_install
  log "写入 systemd 服务文件..."
  write_services
  log "重载 systemd..."
  systemctl daemon-reload
  log "安装完成（未启动、未启用开机自启）。"
}

install_start_enable() {
  install_only
  log "启用并启动服务..."
  systemctl enable --now "$FOX_SERVICE" "$SOEM_SERVICE"
  log "完成：已启动并设置开机自启。"
  log "查看状态: systemctl status $FOX_SERVICE $SOEM_SERVICE"
}

uninstall_all() {
  log "停止并取消自启动（若已存在）..."
  systemctl disable --now "$FOX_SERVICE" "$SOEM_SERVICE" >/dev/null 2>&1 || true

  log "删除服务文件..."
  rm -f "$SYSTEMD_DIR/$FOX_SERVICE" "$SYSTEMD_DIR/$SOEM_SERVICE"

  log "重载 systemd..."
  systemctl daemon-reload
  systemctl reset-failed >/dev/null 2>&1 || true

  log "卸载完成。"
}

main() {
  require_root
  parse_args "$@"

  case "$MODE" in
    install-only)
      install_only
      ;;
    install-start-enable)
      install_start_enable
      ;;
    uninstall)
      uninstall_all
      ;;
  esac
}

main "$@"
