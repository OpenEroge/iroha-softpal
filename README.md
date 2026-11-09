# iroha

用 [sena-rs](https://github.com/OpenEroge/sena-rs)（SoftPAL 引擎的 Rust 跨平台复刻）把《絆きらめく恋いろは -椿恋歌-》移植到 macOS / Linux。

**本仓库不包含任何游戏资源。** 请自行把已购买的游戏目录放到 `iroha_game/`（已被 git 忽略）。

## 快速开始

```bash
git clone --recurse-submodules <this-repo> iroha && cd iroha
# 把游戏目录放到 ./iroha_game（或者 export IROHA_GAME=/path/to/game）
scripts/bootstrap.sh        # submodule、git hooks、编译引擎、建隔离游戏根
scripts/run.sh              # 开窗口运行
scripts/headless.sh 600     # 无窗口诊断，输出到 work/diag/
```

## 目录

| 路径 | 说明 |
|---|---|
| `sena-rs/` | 引擎 submodule，在 `iroha` 分支上开发 |
| `docs/` | 游戏档案、路线图、状态、ADR |
| `scripts/` | 构建 / 运行 / 解包 / 指纹 / git hook |
| `iroha_game/` | 私有游戏资源（被忽略，只读） |
| `work/` | 本地产物：隔离游戏根、解包结果、诊断截图（被忽略） |

Agent 工作流见 [CLAUDE.md](CLAUDE.md)。
