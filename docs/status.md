# 当前状态

> 每次工作结束时更新：做了什么、怎么验证的、下一步做什么。最新的写在最上面。

## 2026-11-09 — M0 框架完成

- sena-rs submodule 在 `5f5b743`（fork 的 main），本地 `iroha` 分支由此新建。
- `cargo build --release -p pal-vm -p pal-pac-unpacker -p pal-assets` 在 macOS (arm64) 上通过。
- 资源层：`pal-assets work/isolated-game paths|list-pacs` 能解析 ARCHIVE.DAT，pac 列表正常（见 `docs/game-profile.md`）。
- headless 冒烟（`scripts/headless.sh 900`）：
  - 能加载脚本：`script_check=0x5C3077EB entry=0x31C points=7085`，SYSTEM.INI 从 PAL 归档读到（Shift-JIS）。
  - VM 在 task 里交替执行 `wait frame` / `wait click`，日志里没有 `UnsupportedCommand`，也没有 panic。
  - 第 900 帧时画面是纯灰，只有 1–2 个纹理（推测是 logo/注意事项画面在等点击），**尚未到达标题**。
- 已知事实：sena-rs 的 AGENTS.md 提到的 `reverse/adr/` 目录**不在** git 里（被 sena-rs 的 .gitignore 排除），本项目的 ADR 放在 `docs/adr/`。

## 下一步
1. M1：批量列出和解包各 pac，用 `dump-pgd-info` 扫描 PGD 格式。
2. M2：给 headless 加 `--diagnostic-click` 或 `--diagnostic-auto-advance` 越过开头画面，在多个帧号截图，看能不能到达标题。
