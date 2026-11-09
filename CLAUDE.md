# CLAUDE.md — iroha 移植工作流

本仓库把 SoftPAL 游戏《絆きらめく恋いろは -椿恋歌-》（`iroha_game/`，Windows 版）移植到 macOS/Linux，引擎是 `sena-rs/` submodule（OpenEroge/sena-rs fork，原本只针对 Koikake）。外层仓库只放文档、脚本、工作流；**所有 Rust 代码改动都在 `sena-rs/` 的 `iroha` 分支上做**。

## 铁律（违反任何一条都要停下来问用户）

1. **`iroha_game/` 是私有、只读的。** 不能 commit，不能在里面写、解包或生成存档，不能 chmod 或改名。也不能把资源内容（台词、图片、脚本反编译出的大段文本）写进任何被 git 跟踪的文件，包括 sena-rs 的测试 fixture 和文档。只允许引用文件名、偏移、哈希和数量。
2. **所有产物放 `work/`**（被忽略）：解包结果放 `work/unpacked/`，诊断结果放 `work/diag/`，临时分析放 `work/re/`。
3. **运行游戏只能指向 `work/isolated-game`**（`scripts/isolated-root.sh` 生成：资源是软链接，`save/` 是真实目录），绝不能把 `iroha_game` 直接传给 `sena`。
4. pre-commit hook（`scripts/hooks/pre-commit`）会拦截游戏路径、二进制资源和 >5MB 的文件，**禁止 `--no-verify`**。被拦了就说明有东西不该提交。
5. `git push`、在 GitHub 上建分支或 PR 这类对外操作，先征得用户同意。

## 开始工作前必读（按顺序）

1. `docs/status.md`：当前进度和下一步。
2. `docs/roadmap.md`：里程碑与验收标准。
3. `docs/game-profile.md`：本作的已知事实和二进制哈希。
4. `docs/adr/`：已接受的结论，**不要重复逆向**。
5. `sena-rs/AGENTS.md`、`sena-rs/reverse/README.md`、`sena-rs/reverse/port-status.md`：引擎侧的规则和现状。注意：那里写的 “Koikake boot facts” 只适用于 Koikake，不能直接照搬到本作。

## 引擎（sena-rs）规则摘要

完整规则以 `sena-rs/AGENTS.md` 为准。重点：
- 代码、注释、sena-rs 内的文档一律用英文。
- 保持 PAL 语义的通用性：**不要硬编码本作的私有变量、台词或文件名**。本作和 Koikake 的差异要靠资源/配置检测或数据驱动处理，不能用 `if game == iroha` 这种分叉。
- 改动不能让 Koikake 回归（跑相关 crate 的已有测试）。
- 逆向确认过的 PAL ABI，要先登记到 `sena-rs/reverse/abi/*.json`，再用 `python3 reverse/abi/generate.py` 重新生成，并用 `--check` 校验。
- 原生 32 位字（native word）保持原样，不要换成 Rust 的 `bool`/`usize`。
- `app_exec` 不能启动宿主程序。

## 标准任务循环

1. 在 `docs/roadmap.md` 里挑一个未完成项（优先选当前里程碑里排在最前的阻塞项）。
2. **调查**：用 `scripts/unpack.sh`、`sena-rs/target/release/{pal-assets,dump-pgd-info,dump-resource,...}`、`--trace-*` 日志、headless 截图。逆向 exe/dll 时，把结论绑定到 `docs/game-profile.md` 里的哈希上。
3. **记录**：新建或更新 `docs/adr/NNNN-*.md`，把原生证据、实现状态、运行时验证分开写。
4. **实现**：在 `sena-rs/` 里开发（确认当前在 `iroha` 分支）。小步提交，commit message 用英文。
5. **测试**：`cargo test --manifest-path sena-rs/Cargo.toml -p <crate>`。已知 `--workspace` 下 `nls_config_fixture` 会因为缺少 `testcase/SYSTEM.INI` 失败，这个与本次改动无关。不要为了让测试通过而把游戏资源拷进 `sena-rs/testcase/`。
6. **运行时验证**：`scripts/headless.sh <frames> [--diagnostic-png-at N:work/diag/x.png ...]`，然后用 Read 工具查看 PNG。必要时再用 `scripts/run.sh` 开窗口。
7. **收尾**：
   - 在 `sena-rs/` 里 commit（必要时征得同意后 push 到 `origin iroha`）。
   - 在外层仓库 commit：更新后的 submodule 指针 + `docs/status.md`（以及 roadmap 勾选、ADR）。
   - status.md 要写清楚：做了什么、用什么命令验证的、观察到什么、下一步做什么。**不要把“编译通过”写成“功能完成”。**

## 常用命令

```bash
scripts/bootstrap.sh                     # 首次：submodule + hooks + 编译 + 隔离根
scripts/isolated-root.sh                 # 重建 work/isolated-game（游戏目录增删文件后执行）
scripts/run.sh [sena args]               # 窗口运行
scripts/headless.sh 600 --diagnostic-png-at 300:work/diag/f300.png
scripts/headless.sh 600 --trace-script   # 逐条跟踪脚本和 extcall（日志很大）
scripts/unpack.sh battle --list-only     # 列出 / 解包 iroha_game/battle.pac 到 work/unpacked/battle
scripts/fingerprint.sh                   # 文件哈希表（更新 docs/game-profile.md 时用）
sena-rs/target/release/pal-assets work/isolated-game list-pacs
sena-rs/target/release/sena --help       # 全部诊断参数（--diagnostic-click、--trace-buttons …）
```

环境变量：`IROHA_GAME` 可以覆盖游戏目录位置；`RUST_LOG=debug` 可以拿到更细的日志。

## 编码提示

- 游戏内文本是 Shift-JIS（`--nls sjis`），汉化覆盖层预计是 GBK 或 UTF-16。
- 读取 `iroha_game` 里的说明文件：`iconv -f SHIFT_JIS -t UTF-8 readme.txt`，`iconv -f UTF-16 -t UTF-8 汉化信息及注意事项.txt`。

## 文档语言

外层 `docs/`、`CLAUDE.md`、`README.md` 用中文；`sena-rs/` 内的一切用英文。
