# 当前状态

> 每次工作结束时更新：做了什么、怎么验证的、下一步做什么。最新的写在最上面。

## 2026-11-09 — M1 资源层 + M2 启动到标题

sena-rs `iroha` 分支：`0640fb1`（修好 pal-vm 测试的编译）、`438b4e4`（gosub 操作数解码 + trenka 接口 evidence）。

### 做了什么 / 观察到什么
- **M1**（ADR-0001）：18 个 pac 全部能解包（37,480 个条目，exit 0，魔数正确）。26,627 个 PGD 全部能被 `dump-pgd-info` 解码，没有不支持的格式；抽查 PGD3 差分图，合成结果正确。ARCHIVE.DAT 是 3 个逗号分隔的 profile，默认用 0。SYSTEM.INI 在 `csv.pac` 里（1280×720，位图字体 type 4）。视频是 MPEG-1 PS，音频是 OGG。
- **M2**（ADR-0002）：trenka 通过 delay-load 导入 PAL；Pal.dll 约等于 Reference 版本去掉多语言导出。找到了主 opcode 表 `0x64C890` 和 category 表 `0x626098`，alias 区域和 Reference 不同（本作脚本用不到，暂时不受影响）。脚本用到的 419 种 extcall 在 trenka 里都有 handler；sena 中有 86 种会 Skip（清单见 ADR-0002）。
- **修复**：trenka 的 gosub 会解析操作数，脚本里有 `gosub var[1]`；sena 之前只在 registered profile 下才解码，现在一律解码（普通的 point id 行为不变）。反汇编器也一并修好（以前加上 `--point-dat` 会直接报错退出）。
- **发现上游测试状态**：pal-vm 的 lib 测试原本**无法编译**（wgpu 30 升级遗留），已修复。另外有 3 个基线上就失败的用例：`nls_config_fixture`（已知）、`operand_fixture::high_frequency_pal_extcalls_are_stack_safe`、`pal-decompiler test_bgm_play_resource_id`。

### 验证
- `cargo test -p pal-script -p pal-asset -p pal-disassembled -p pal-vm --no-fail-fast`：除上面 3 个基线失败外，全部通过（pal-vm lib：248 通过）。
- `scripts/headless.sh 3000 --diagnostic-auto-advance --diagnostic-png-at 300:work/diag/m2/a300.png ...`：第 300 帧是 logo 视频，**第 900 帧到达标题**，到第 3000 帧一直稳定，没有 UnsupportedCommand。截图已用 Read 工具查看。
- gosub 修复**还没有运行时验证**：开启 `--trace-script` 跑了 2100 帧，动态 gosub 一次也没执行到。
- 音频没有做运行时验证（`--no-audio`）。

### 下一步（M3）
1. **阻塞**：用 `--diagnostic-click-when-hit-enabled 280:184` 点击 GAME START 后，画面在 pc `0x82490` 停住，标题上方弹出一个“附加内容已解锁”类型的提示框，没有进入游戏。先用 `--trace-script` 看提示框由哪个条件触发（重点怀疑返回 0 的 18:5B/60–63、14:0D/18），再看怎么关闭它。
2. 把开头会碰到的 Skip extcall（18:86/87 TIPS 已读标志、18:88/89/91/96–99、14:13/24、5:8、3:59、2:47）对照 trenka 的 handler 逐个确认语义，再实现。cat 18 的 registered 语义需要一种不依赖 Pal.dll 导出的能力判定。
3. 进入游戏后验证第一句台词、立绘、背景，以及音频（去掉 `--no-audio`，或者开窗口实测）。

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
