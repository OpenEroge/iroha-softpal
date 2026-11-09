# 移植路线图

目标：用 sena-rs（SoftPAL 的 Rust 复刻）在 macOS/Linux 上完整运行《絆きらめく恋いろは -椿恋歌-》。先做日文原版，汉化排在后面。

每个里程碑的“完成”都要求**运行时验证**（headless 截图或日志、窗口实测），编译通过或 handler 数量都不算完成。进度记在 `docs/status.md`。

## M0 框架 ✅
- git 仓库、`sena-rs` submodule（`iroha` 分支）、脚本、hook、文档、CLAUDE.md。

## M1 资源层
- [x] 所有 `.pac` 都能列出和解包，不报错（`scripts/unpack.sh <name> --list-only`）。
- [x] PGD 变体全部能解码（用 `dump-pgd-info` 批量扫描 st/ev/bk/system/battle），整理出不支持的格式清单。
- [x] 弄清 ARCHIVE.DAT 三行的含义，以及引擎选用哪一行；找到 SYSTEM.INI 的真实来源和关键键值（逻辑分辨率、字体）。
- [ ] 音频：OGG/WAV/`.MIX`/BGM.CSV 循环点；视频：`movie.pac` 的容器与编码（MPG/WMV？）。（格式已查明：全部 OGG + MPEG-1 PS，logo 视频能播放；音频播放尚未做运行时验证，放到 M3）
- 产出：一份 ADR，记录与 Koikake 的资源差异。→ [ADR-0001](adr/0001-resource-layer.md)

## M2 VM 启动到标题
- [x] 统计 `SCRIPT.SRC`（Sv20，7085 points）的 extcall，和 sena-rs 的 extsig 表做差，列出未知或被跳过的 extcall。
- [x] 逆向 `trenka.exe` 的 extcall slot 表和 `dll/Pal.dll` 的导出表，与 Koikake 的版本对比，按 sena-rs 的 ABI 规则登记。
- [x] headless 能经过 logo/注意事项画面，到达标题界面并截图。→ [ADR-0002](adr/0002-native-interface-and-extcalls.md)

## M3 主线 ADV
- [ ] 开始游戏 → 第一句台词；文本（`DEFAULT_FONT.DAT`/字体）、立绘、背景、表情（face）、BGM/SE/语音。
- [ ] 选项、存读档（`save/`）、系统菜单、backlog、TIPS（`tips.pac`）、SD 演出（`sd.pac`）、`.ANI` 镜头动画。
- [ ] 能用窗口模式完整玩通一条线（人工验收）。

## M4 战斗 / 特殊系统
- [ ] 确认 `battle.pac` 对应的逻辑在哪里：脚本侧还是 exe 内置。如果是 exe 内置，就逆向 `trenka.exe` 里的专用 extcall 或子系统。
- [ ] 以引擎通用 extcall 的形式实现，不在 VM 里硬编码本作逻辑。

## M5 汉化（mai 覆盖层）
- [ ] 逆向 `mai.dll`：hook 了哪些点、`.mai` 的封装（加密/压缩）方式、`word.mai` 的作用。
- [ ] 在 sena-rs 里以“VFS 覆盖层”的形式实现（例如 `--overlay <dir>` / `--patch mai`），按文件名映射替换 TEXT.DAT、PGD、CSV、MPG。
- [ ] 处理 GBK 文本和中文字体；`trenka_cn.exe` 与原版的差异（字符集、字体名）。

## M6 打包与发布
- [ ] macOS：复用 `sena-rs/platform/macos` 打 .app/DMG；Linux：x86_64/aarch64 构建。
- [ ] 用户指南：如何把自己购买的游戏目录接入（本仓库不分发任何游戏资源）。
