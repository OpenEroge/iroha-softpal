# 0002: trenka.exe / Pal.dll 原生接口、extcall 覆盖与 gosub 操作数

- 状态：Accepted（slot 表和接口差异）；Proposed（未实现的 extcall 的处理方式）
- 日期：2026-11-09
- 适用范围：`trenka.exe` sha256=`1038558f…09fd`，`dll/Pal.dll` sha256=`2ef61fc3…8463`，`data.pac`（SCRIPT.SRC check `0x5C3077EB`）
- 引擎侧记录：`sena-rs/reverse/iroha-native-profile.md`、`sena-rs/reverse/evidence/iroha-trenka-interface-inventory.json`

## 问题

M2：统计脚本用到的 extcall，逆向 trenka 的 slot 表和 Pal.dll 的导出表，和 sena 已经审计过的版本做比较，并让 headless 运行到标题画面。

## 原生证据

工具：pefile + capstone（装在 `work/re/.venv`），分析脚本放在会话 scratchpad，产物在 `work/re/`。

1. **PAL 绑定方式**：trenka.exe 的普通导入表里**没有** PAL.dll，而是通过 **delay-load** 导入 213 个 PAL 函数，和 Reference Game.exe 的做法相同。trenka_cn.exe 只是把 `COMDLG32.dll` 的导入换成了 `mai.dll`（这条留给 M5）。
2. **Pal.dll 导出**有 285 个。和 sena 审计过的三个版本相比：
   - **Reference**（290 个）：本作只多出 `?PalGetlpPool@@YAPAEXZ`，少了 6 个多语言/坐标相关的导出（`PalGet/SetLanguage`、`PalSystemCN/TCPathSet`、`PalSpriteGetPosX/Y`）。**这是最接近的版本。**
   - Koikake（262 个）：本作多 23 个（触摸/手势、`PalButtonMode/Reset`、`PalSoundGetParam/Status/NowChannel`、`PalSpriteSetLayer`、`*Float` 旋转、纹理存取等），没有缺少的。
   - Totsulover（369 个）：本作缺 85 个，其中包括 registered profile 的判定标志 `PalSystemPathInit`、`PalGetChangeWindowModeTime`，所以 sena 不会启用 registered profile（这是正确的）。
   - trenka 导入的函数比 Reference Game.exe 多 `?PalGetlpPool`、`PalSoundGetVolumeChannel`，少 4 个语言相关函数。trenka 导入的 213 个名字 Pal.dll 全部有导出。
3. **主 opcode 表**位于 `0x64C890`，共 265 个 slot，分派时不做越界检查（`0x436F34`、`0x44A0F8`、`0x44A6A3`）。**extcall category 表**位于 `0x626098`，24 项，分派函数是 `0x42D920`；category 为空时返回 0，并且不写目标槽。
4. **alias 区域和 Reference 不一样**：本作的起点是 10:40、5:82、6:98、9:110、12:171、2:176、13:226、7:254，而 Reference 是 5:80、6:96、9:108、13:224、7:252。也就是说 cat10 和 cat2 各多 2 个 slot，cat9 少 2 个。sena 的 `primary_aliases.rs` 写死了 Reference 的布局，不过**本作脚本只用到 1..33 号 primary opcode**，所以目前不受影响。
5. **gosub 操作数**：`gosub_point` 的处理函数（`0x42D7B0`）通过通用的操作数解析函数 `0x42D2E0` 取得跳转目标。primary 1..19、26..28、30..33 也都调用它。高 4 位为 0 时，解析函数直接返回原始值（即立即数）。脚本在 pc `0x86D98` 处有 `gosub var[1]`（原始值 `0x40000001`）。
6. **cat 18 的语义**：抽查了 88 号（`IsNetworkAlive`）、89 号（`GetSystemMetrics(0x5E)`+`PalIsTouch`）、91 号（`PalTouchEnable`）、96 号（`Pal3DIs`），含义都和 sena 里 registered profile 的实现一致。但本作的 Pal.dll 没有 registered 的标志导出。86 号负责设置 TIPS 记录（每条 0x6C 字节）中 +0x68/+0x69 两个字节；87 号是 `tips_acc_save`，把这些标志写进文件。

## 脚本 extcall 统计（SCRIPT.SRC）

- 用到的 primary opcode：1..33（不含 22、34 及以上）。extcall 一共 41,713 处调用，419 种不同的 (cat, idx)。
- **这 419 种在 trenka 里全部有非空的原生 handler**。
- 用临时的 `#[ignore]` 探针测试（已删除，没有提交）逐个调用 sena 的 `dispatch_extcall`：Value 311、Continue 15、Wait 7、**Skip 86**（共 418 处调用）。Skip 表示 sena 没有对应的 handler，写 0 后继续执行：

| cat | 数量 | idx |
|---|---|---|
| 2 | 2 | 35, 47 |
| 3 | 5 | 33(sp_anime_clear), 42(sp_load_wait_time), 43(sp_draw), 58(drawtext), 59 |
| 4 | 1 | 5(bgm_set_volume_users) |
| 5 | 2 | 8(channel_error_set_se_info), 13(se_set_pan) |
| 8 | 5 | 27(btn_blt), 28(btn_link), 30(btn_get_link), 31(btn_set_tips), 32(btn_get_tips) |
| 9 | 1 | 59 |
| 10 | 2 | 38(histload), 39 |
| 14 | 8 | 13, 15, 16, 21, 22, 23, 24, 25 |
| 15 | 4 | 1, 3, 8, 9 |
| 17 | 2 | 31, 35 |
| 18 | 54 | 41–48, 50, 54, 55, 57, 59–68, 72–76, 78, 79, 82–84, 86–100, 106–109, 111, 113, 114 |

（探针运行时子系统都传了 None，所以个别 handler 可能只在缺少子系统时才返回 Skip。以运行时的 `unimplemented extcall` 日志为准。）

## 决策 / 结论

- 本作的原生接口按“接近 Reference、但没有多语言支持”的版本对待，**不加入** `NativeBuild` 的身份表（目前没有任何逻辑依赖它）。
- gosub 的目标一律按操作数解码（sena `438b4e4`）。对普通的 point id 来说结果完全一样，因此不会影响 Koikake。
- 未实现的 extcall 按 M3 的需要逐个补上，**不要**为了它们打开 `registered_softpal`：这个开关还会改变 SE 参数约定、字体、按钮等很多行为。像 cat 18 的 88/89/91/96–99 这类调用，需要一个和 Pal.dll 导出无关的能力判定（例如根据原生 slot 表、脚本特征），做法待定。

## 实现状态（sena-rs `iroha` 分支）

- `0640fb1`：修好 pal-vm 测试代码在 wgpu 30 下的编译错误（`get_mapped_range` 改为返回 Result，纹理像素改为 `Arc<Vec<u8>>`）。修之前 pal-vm 的 lib 测试根本无法编译。
- `438b4e4`：VM 的 gosub 改为解码操作数；反汇编器遇到非立即数的 gosub 时输出 `PointOperand`；新增测试 `gosub_resolves_variable_point_operand_without_registered_profile`；提交 evidence JSON 和 md。
- `reverse/abi/*.json`：**没有改动**。本次没有确认任何新的 PAL 导出函数签名，gosub 属于 VM opcode 的语义，不属于 PAL ABI。
- 测试：`cargo test -p pal-script -p pal-asset -p pal-disassembled -p pal-vm --no-fail-fast` 全部通过，只有以下 3 个**原本就失败**的用例（在没有本次改动的基线上同样失败）：
  - `pal-vm nls_config_fixture::startup_config_reads_system_ini_logical_size_before_vm_runs`（缺 testcase，已知）
  - `pal-vm operand_fixture::high_frequency_pal_extcalls_are_stack_safe`（`var[1] should report success`，基线同样失败）
  - `pal-decompiler tests::test_bgm_play_resource_id`（基线同样失败）

## 运行时验证

- `scripts/headless.sh 3000 --diagnostic-auto-advance --diagnostic-png-at 300:… 900:… 1800:…`：第 300 帧显示 CRYSTALiA logo（MPEG-1），第 900 帧进入**标题画面**（菜单：CONTINUE/DATA LOAD 是灰的，GAME START、EXTRA MODE、SPECIAL、SYSTEM、GAME END 可用），到第 3000 帧一直稳定，没有 UnsupportedCommand，也没有 panic。截图在 `work/diag/m2/`。
- 到标题为止日志里出现的 Skip：18:86/18:87（标题循环里每帧轮询，各 157 次）、18:88/89/91/96–99、14:13/24、5:8、3:59、2:47。
- 在开启 `--trace-script` 的 2100 帧里有 383 次 gosub，**动态 gosub 一次也没执行到**，所以 gosub 修复目前只有原生证据和单元测试支撑。

## 未解决

- 用 `--diagnostic-click-when-hit-enabled 280:184` 点击 GAME START 后，画面在 pc `0x82490` 停住，标题上方弹出一个“附加内容已解锁”类型的提示框，没有进入游戏。需要查清这是正常提示（安装目录里带有附加补丁）还是某个 Skip（返回 0）的 extcall 导致的误判。这是 M3 的第一个阻塞项。
- 86 个 Skip 的 extcall 的语义（逐个看 trenka 里的 handler）。
- registered 语义的 cat 18 调用如何不依赖 Pal.dll 导出来启用。
- alias 区域和 Reference 不同。如果以后某个脚本用到高位的 primary opcode，就要按版本选择 alias 表。
