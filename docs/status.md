# 当前状态

> 每次工作结束时更新：做了什么、怎么验证的、下一步做什么。最新的写在最上面。

## 2026-11-10 — 支持高分屏（HiDPI）

详见 [ADR-0008](adr/0008-hidpi-presentation.md)。sena-rs `edbc0d3`。

### 做了什么
- **等比缩放加黑边**：窗口比例和 16:9 不一致时（例如 3024×1964 全屏）不再拉伸。wgpu、软件渲染器和鼠标映射用同一个视口。
- **高清文字**：ADV 正文、名字、backlog 按窗口的整数倍率（Retina 上是 2）重新光栅化，作为 sprite 的高清副本交给渲染器。只有矢量字体（`--patch mai`）会更清晰；位图字体维持原样。
- **backlog 只在内容变化时重绘**：2x 下每帧开销从约 6.5ms 降到和 1x 相当。
- **诊断工具**：
  - headless 新增 `--diagnostic-device-size WxH`；
  - wgpu 的 `--window-dump-frame-at` 改为真实 GPU 回读。

### 验证
- `cargo test -p pal-vm`：484 个全部通过，新增 8 个；pal-script、pal-asset、pal-disassembled 也全部通过。
- 用改动前的二进制做基准，在相同输入下逐帧对比：
  - 逻辑分辨率 PNG：`--patch mai` 7 帧、无补丁 2 帧，逐字节一致，PC 轨迹完全相同。
  - backlog 的打开、滚动、悬停、点击 4 个状态也一致。
- headless 2560×1440 / 3024×1964：文字明显更锐利，位置不变；黑边正确；backlog 正常（`work/diag/hidpi/`）。
- 真实窗口：1280×900 窗口的 GPU 回读确认黑边正确，没有 wgpu 错误。

### 下一步
- 请用户用 `scripts/run.sh --patch mai` 开窗口确认：文字清晰；全屏后有上下黑边，没有拉伸；点击位置准确。（窗口诊断模式点不进游戏，wgpu 上的高清文字没能自动截图。）

## 2026-11-10 — 修复同一角色同屏出现两次（立绘表情切换）

详见 [ADR-0007](adr/0007-sprite-expression-slot.md)。

### 问题与原因
- 用户截图：椿同屏出现两次，左边是旧表情，右边是新表情。
- 原因：表情切换宏（point 393）先用 18:3 把立绘文件映射到角色，再按角色找槽位。trenka 的 18:3 是“File.dat 文件名里是否包含某个前缀”（`strstr`，不区分大小写）；sena 沿用了 Game.exe 的“不相等”语义。结果所有文件都被认成角色 0，新表情被送进别的角色的槽位，旧表情留在原处。

### 改动
- sena-rs：给 trenka 加 18:3 包装 `ext_string_contains_ignore_case`，新增 1 个测试。

### 验证
- `cargo test -p pal-vm --lib`：286 个全部通过。
- 450,000 帧自动推进（`--patch mai`）：“no current image” 警告从 9 次降到 0，没有 unimplemented。
- 用户截图里的场景（脚本 0x195FB0，约第 440,000 帧）：修复前出现两个椿（`work/diag/twin/grid.png`）；修复后椿在左边原地切换表情，女仆留在右边（`grid3.png`）。

### 下一步
- 复查 ADR-0005 里第 1068680 帧附近“两个造型相同的角色”的结论。

## 2026-11-10 — 修复 ADV 右侧菜单（MENU 面板按钮不显示）

详见 [ADR-0006](adr/0006-adv-menu-script-thread.md)。不加 `--patch` 时也有这个问题。

### 问题
用户截图：点 `>>` 后，MENU 面板只有底板和一个“快速存档”提示框，按钮全部看不见。

### 原因
菜单由脚本线程 point 2367 驱动：悬停时滑入，移开时滑出。sena 在四个地方与原生不一致：
1. 线程函数 `ret` 一次就被停掉，主脚本等待时也不运行线程。原生是每帧都重新调用。
2. 为 Koikake 写的宿主端菜单模拟拦截了点击，自己切换显示状态，结果只显示了底板，按钮的 alpha 还是 0。
3. 本作套用了 Koikake 的 action 表大小（8×32）。原生是 16 个 bank、每个 64 条 line，菜单用到的 lane 最大是 47。
4. trenka 的 `sp_set_pos_move` 应该能移动打包的按钮槽位，sena 没有处理。

### 改动
sena-rs：
- 线程函数返回后下一帧重新进入，主脚本等待时也调度，指令预算与主脚本相同。
- 删除宿主端菜单模拟。`btn_enable` 不再隐藏按钮。
- `NativeBuild::wide_action_tables`、`sprite_slots_resolve_buttons`。
- 15:8 返回栈深度。
- 新增 2 个测试，替换 1 个旧测试。

### 验证
- `cargo test -p pal-vm -p pal-script -p pal-asset -p pal-disassembled`：全部通过（pal-vm lib 285 个）。`cargo check --workspace --all-targets` 只有原来就有的 warning。
- headless（`work/diag/m5menu/`），鼠标位置靠注入的点击移动：
  - 区域外只显示 `>>`。
  - 移到面板上，按钮全部滑入到正确位置，`>>` 隐藏。
  - 移开后滑出。
  - 加 `--patch mai` 时，点 Q.SAVE 写入 `save999.dat`，点 SYSTEM 打开中文 SYSTEM 画面。
- 标题画面：新旧二进制在相同输入下逐帧截图一致。
- 剧情回归：200,000 帧自动推进（`--diagnostic-auto-advance-min-frames 30`），剧情持续推进（`r50k/r120k/r199k.png`），没有 unimplemented，没有 panic。只有 sprite transition 相关的诊断 WARN（`scale-inherit`，以及 7 条 slot 12 “no current image”），与菜单无关；这次没有和旧二进制对比过。

### 下一步
- 请用户开窗口验收：`scripts/run.sh --patch mai`，把鼠标移到右侧呼出菜单，试一下各个按钮。
- 删除的菜单模拟原本是为 Koikake 写的。原理上 Koikake 也应该由脚本线程驱动菜单，但本机没有 Koikake 资源，无法做运行时验证。

## 2026-11-10 — M4 战斗、M5 mai 汉化覆盖层

sena-rs `iroha` 分支 `d0b4dd2`，详见 [ADR-0005](adr/0005-m4-battle-m5-mai-overlay.md)。

### 做了什么
- **M4 战斗**：确认 `battle.pac` 的资源名只出现在 `FILE.DAT`，exe 里没有。用到它们的是脚本 `0xB9000–0xDE000` 区间的演出函数和各章 SE 调用，只调用通用 extcall，也不等待输入。结论：战斗是非交互的脚本演出，不需要专用 extcall，M3 的 extcall 审计已经覆盖。
- **M5 mai.dll 逆向**：
  - `trenka_cn.exe` 只改了一个导入。
  - `mai.dll` 挂钩了 `PalFileCreateEx`（chg）、`PalSpriteLoad`（img 的 PNG）、`PalFontSetType`（4→1）、exe 的文本记录读取（`text.mai` 按 id 替换，id 0–4 除外），以及 `CreateFontA` / `GetGlyphOutlineA`（SimHei + 码表）。
  - `word.mai` 是译文用到的字符集合，DLL 由它生成“伪 Shift-JIS”码表，所以译文并不是 GBK。
- **M5 实现**：`--patch mai`。
  - `pal_asset::MaiCharset` / `Nls::Mai`：码表不拷贝 DLL 数据，在运行时重新生成；补丁没分配的码位回退 cp932。
  - `MaiPatch` + `ResourceManager::set_mai_patch`：chg 文件覆盖所有搜索路径。
  - `CoreAssets::apply_text_patch`：按原记录偏移映射到补丁里同 id 的记录。
  - `decode_asset_image`：尺寸相同才替换像素。
  - 字体：类型 4→1；SimHei 由宿主字体代替（macOS 上是 STHeiti）。
- 新增测试 12 个（pal-asset 6 个，pal-vm 6 个）；`TIPS.CSV` 和 `movie` 加载时会在 debug 日志里记下来源。

### 验证
- `cargo test -p pal-vm -p pal-script -p pal-asset -p pal-disassembled`：全部通过（pal-vm lib 284 个）。`cargo check --workspace --all-targets` 没有错误。
- 码表与 DLL 算法的模拟结果对比，2,996 个字符全部一致。补丁加载：3 个 chg 文件、661 张图、25,793 条文本，替换了 Text.dat 的 25,788 条。
- headless 截图（`work/diag/m5/`）。命令示例：`scripts/headless.sh 12100 --patch mai --diagnostic-auto-advance ...`，空存档用 `work/re/m5/fresh.sh` 跑。
  - 汉化组 staff 的 CAUTION 画面和 chg 里的 LOGO 动画
  - 中文正文和名字框
  - SYSTEM、SAVE 画面和确认框
  - 收藏语音画面
  - 游戏内 TIPS 小窗口（`TIPS.CSV.mai` 读到 272 条）
  - 存档后，存档格里的中文摘要正确
- M4：2,300,000 帧整线自动推进，在战斗区间停留 14,137 帧，没有 unimplemented，没有 panic；第 467200 帧附近的战斗截图序列见 `work/diag/m4/seq_a.png`。

### 结论 / 未完成
- 当前 `work/isolated-game/save` 是之前整线跑出来的状态：自动点击把 TIPS 开关（`mem_system[110]`）关掉了，所以 EXTRA 里看不到 TIPS 标签页，游戏内也没有 TIPS。这是存档数据造成的，不是引擎问题；用空存档时一切正常。
- 没有原生 Windows 截图可以对照，所以 SimHei 与 STHeiti 的字形差异、战斗演出的细节只做了合理性检查。
- 汉化补丁的说明文件写着“严禁拆解、二次修改、移植应用于任何平台”。本仓库不分发、也不修改补丁文件，只在运行时读取用户本地的副本。
- 窗口模式运行汉化版：`scripts/run.sh --patch mai`（需要用户人工验收）。
- 下一步：M6 打包与发布。

## 2026-11-09 — M3 第三轮：收藏语音、游戏内 TIPS、extcall 参数审计

sena-rs `iroha` 分支 `849c2fd`..`5c16593`，详见 [ADR-0004](adr/0004-m3-native-subsystems.md) 第 6–9 节。

### 做了什么
- **收藏语音**：18:60–68，`save/favoice.dat`，格式与原生相同。用到的辅助扩展有 18:57 `strcut`、18:106、18:107。
- **backlog 分隔线**：14:25 原来以为是收藏图标，逆向后确认是每条记录之间的分隔线（`HISTORY_LINE_*`）。
- **sprite 画布**：trenka 的 3:32 `sp_create` 有 6 个参数，带名字、位置和尺寸。3:22 `sptext` 在 slot 已有 sprite 时，把文字画进现有表面（Totsulover 也是这样，因此对所有版本生效）。
- **游戏内 TIPS**：ADV 渲染器原来先把 `<dN>` 标签剥掉了，所以 TIPS 词条从来没有被识别。修复后补上了 3:58 `drawtext`、8:27 `btn_blt`、8:31/32。词条会以绿色高亮，点击后在 (8,334) 弹出 TIPS 小窗口。
- **3:14 改正**：trenka 写的是基础位置（绝对移动），不是另一个叠加的图层。原来按叠加处理，TIPS 小窗口的坐标被算了两遍。
- **三行台词**：文本块的高度改为按每行实际步进计算，最后一行不再被裁掉。
- **参数个数审计**：脚本用到的 419 个 extcall 坐标，弹栈个数现在全部与原生一致。顺带修好了这些：
  - 3:13 每次调用往栈上多留 2 个值
  - 9:55 `get_font_color`（所有版本）
  - 2:18/19 `text_n`/`text_cat`：原来这两处台词根本不显示
  - 2:20 `set_history`、3:38 `sp_bitblt`
  - 10:29 存档“データ移動”
  - 其余的小 wrapper
- trenka 专属的坐标统一登记在 `TRENKA_OWN_EXTCALLS` 表里，由 `NativeBuild::defines_extcall` 判定。

### 验证
- `cargo test -p pal-vm -p pal-script -p pal-asset -p pal-disassembled`：全部通过（pal-vm lib 278 个）。
- headless 截图都用 Read 工具看过（`work/diag/m3/`）：
  - backlog 分隔线（`sep1/sep2`）
  - 点击 backlog 头像后写出 `favoice.dat`；VOICE MODE 显示 “001/500”、头像和截断后的台词（`v_mode4`）
  - EXTRA → TIPS 的列表和详细说明（`t_a2`、`t_detail`）
  - 游戏内 TIPS：auto-advance 下约第 28440 帧出现词条，点击后小窗口位置正确（`tx3`）
  - 三行台词不再被裁（`ty3c`）
  - 存档“データ移動”（`mv2/mv3`）
  - SAVE/SYSTEM 回归（`r_save`、`r_system`、`r2_pair`）
- 600000 帧自动推进：剧情持续推进，没有 unimplemented，没有出现任何选项（`long2/sheet.png`）。
- 1,000,000 帧自动推进：没有 unimplemented，没有 panic。SD 演出 SD001A 出现在第 632000 帧前后，之后还有 SD002A–D、SD003A，截图检查过（`sd/png/sheet.png`）。
- 音频资源：BGM.CSV 59 行的循环点全部为 0，OGG 也没有 loop 标签，所以 BGM 都是整首循环。`.MIX` 用 sena 的解码路径可以合成为混音（临时探针，没有提交）。
- 栈深度：30000 帧里，每次 `text` 调用时的栈深度一直稳定，不再增长。

- **整线通关（自动）**：auto-advance 在约第 2,250,000 帧通关，回到通关后的标题画面。途中只有 18:92 未实现，它是 `AdvDebugOutputCore` 的包装，弹 8 个值，`5c16593` 已补上（18:90 同理）。修复后重跑到第 2,300,000 帧，没有 unimplemented，没有 panic（`route/sheet.png`、`route/confirm.png`）。
- **音频实测**：用 sena 的解码路径解码 BGM08（466.56 秒）、BGM01、SE01_A000A、VO01_00001，时长与 ffprobe 一致，RMS 和峰值都正常。窗口模式启动 20 秒没有崩溃。

- **人工验收（2026-11-10）**：用户开窗口试玩，原话：“音乐是正常的”，“音效正常，可以玩，和原本的差不多”。M1–M3 至此全部完成。

### 结论 / 未完成
- **选项**：本作没有原生的选项块（脚本里没有 6:1/6:2/6:3），600000 帧里也没有遇到。
- **EXTRA 子菜单偏左**：原生的 action 提交语义和 sena 一致，大概率就是原生的样子；需要原生截图对照才能下结论。
- 收尾补完（`3e9c346`、`3b5dd04`）：
  - 4:5 按原生方式线性淡变 BGM 声道音量；4:16/4:17 改用 AudioSystem 里对应 PalSoundGetNowChannel/GetStatus/GetParam 的实现。
  - 3:58 结束时按原生裁剪 sprite 的显示区域。
  - `wsprint` 支持 `%t`/`%n`/`%'`：MUSIC MODE 的曲名原来是空的，现在能显示。
  - 修正了两个过时的上游测试：`operand_fixture` 里 btn_get_push 要先压入 group，btn_set_hit 不写目标槽；`nls_config_fixture` 在本地没有 Koikake testcase 时跳过。现在 `cargo test -p pal-vm` 全部通过，没有失败用例。
  - 本分支自己的模块（ani、tips_dictionary、voice_favorites、trenka_wrappers、native_profile）clippy 没有警告。clippy 无法完整跑完，是因为上游的 `wmv-decoder`、`ffi.rs`、`fx.rs` 里有 deny 级别的问题，这些文件本分支没有改动。
  - 截图检查过：MUSIC/CG/SCENE 模式（`music3`、`cgscene`），TIPS 回归（`tz`）。

## 2026-11-09 — M3 第二轮：原生子系统

sena-rs `iroha` 分支 `4581a9d`..`6734cf4`，详见 [ADR-0004](adr/0004-m3-native-subsystems.md)。

### 做了什么
- **识别 trenka 版本**：用完整文件哈希识别 `NativeBuild::Trenka`。逐个比对后，把 SE、backlog 图标、历史导航、host 查询等与 registered 版本一致的 extcall 坐标，通过一张逐坐标的数据表开放给本作，不打开整个 registered profile。
- **完整的 `.ani` 解释器**（`ani.rs`），本作 351 个程序全部能运行；新增 3:33 `sp_anime_clear`；`sp_set_pos_ex` 按版本区分（trenka 写位置层，审计过的 Game.exe 写旋转层）。
- **action 段类型 16（rect 补间）和 20（mask 显现）**：剧情里的斩击特效原来是黑屏，现在能正常显示。
- **存档界面**：去掉了空存档位上的幽灵缩略图；日期和时间不再重叠；台词按原生规则换行。
- **TIPS 词典**（18:82–87）、存档目录和字符串辅助函数、全局整数表、18:108。
- **INI 读取**：`TIPS_FLAG = 1;` 这种值现在能正确读出；文件名改为按 File.dat 解析。

### 验证
- `cargo test -p pal-vm`：lib 265 个通过；集成测试只有两个基线就失败的用例（`nls_config_fixture` 缺少 testcase；`operand_fixture::high_frequency…` 是上游对按钮栈行为的预期，与本次改动无关）。`pal-script` 通过。
- headless 截图检查过（`work/diag/m3/`）：系统菜单、SAVE→LOAD 往返（恢复到原来那句台词）、backlog（有头像）、TIPS 画面、EXTRA 子菜单、斩击特效、存档 “NEW!” 动画。
- 模拟首次启动（清空 `work/isolated-game/save/sena_rs`）：读到 `TIPS_FLAG=1`，加载 272 条词条，写出 `save/tips_acc.dat`。
- 180000 帧自动推进（游戏内约 48 分钟）没有卡住。

### 下一步
1. 收藏语音（18:60–68、14:25）。
2. EXTRA 子菜单偏左约 200px（原本就存在的问题，需要逆向按钮与 action 的交互）。
3. 找到第一个选项并验证；3:58 `drawtext`。
4. 关窗保存系统数据；窗口模式下人工确认音频。

## 2026-11-09 — M3 开局：进入游戏，文本/立绘/背景/音频

sena-rs `iroha` 分支：`dd36acb`（sp_get_filename 去后缀）、`400a53a`（SE 5:2 按原生顺序解析参数）、`5a6d48f`（`--diagnostic-realtime`）、`1f7fc2a`（native profile 文档）。详见 [ADR-0003](adr/0003-m3-game-start-and-av.md)。

### 做了什么 / 观察到什么
- **M2 留下的“GAME START 卡住”其实不是卡住**：pc `0x82490` 是附加内容通知的 toast 子程序，`mem_system[262]==0` 时连着显示 4 条，合计约 1100 帧。等通知播完再点 GAME START，就能进入序章。
- **修复 1**：开场演出用 `sp_get_filename` 取立绘名，再拿这个名字 `sp_set`。sena 返回的名字带 `.pgd`，加载器又追加一次后缀，结果立绘丢失。按原生证据（名字保存在记录 +0x254，不带后缀），现在返回原名。
- **修复 2**：SE 5:2 的第 5 个参数是声音组选择值（查表 {5,4,6}），不是音量。sena 原来把它当成 1% 音量，SE 几乎听不见。现在 flags/淡入/声音组都按原生语义处理。5:1 的参数个数因版本而异（本作压 3 个，Koikake 压 4 个），这次没动。
- **测试方法问题**：原来的 headless 帧之间不睡眠，开着音频时 VM 时钟远远跑在实际播放前面，按钮反应要等点击音效播完，因此点不进去。新增 `--diagnostic-realtime`，外层用 `HEADLESS_AUDIO=1 scripts/headless.sh …` 开启。

### 验证
- `scripts/headless.sh 8000 --diagnostic-auto-advance --diagnostic-auto-advance-min-frames 90 --diagnostic-click-when-hit-enabled 280:184 --diagnostic-png-at …`：第 3600 帧出现第一句台词，背景、立绘、名字框、VOICE 图标正常；后续有事件 CG 和 face 小头像。截图用 Read 工具看过（`work/diag/m3/sheet.png`）。
- 实时音频运行（3400 帧，第 2500 帧点击）：play 了 BGM08、系统语音、台词语音 VO02/VO09、SE；SE 的有效音量从 56 恢复到 5600。**还没有人耳确认**。
- 30000 帧 auto-advance：剧情一直在推进；OPENING 视频播放 124 秒，画面和 ffmpeg 解码结果一致（35 秒处的“花屏”是 OP 本身的特效）。
- `cargo test -p pal-vm`：lib 250 个通过；集成测试只有两个基线就失败的用例。`cargo test -p pal-script` 通过。

### 下一步
1. 开窗口（`scripts/run.sh`）人耳确认 BGM/SE/语音，顺带检查 BGM 循环点。
2. `.ANI` 字节码：`ANI_LINE_EFFECT*`、`ANI_SYM_ASERI` 等多指令动画还不支持（开场 letterbox 线条没有过渡效果）。
3. 5:1 参数个数按版本区分（本作 22 处调用，执行到时会造成栈错位）。
4. 关闭窗口时保存系统数据（否则附加内容通知每次启动都会重新显示）；先确认原生退出时是否会写 system.dat。
5. M3 第二项：选项、存读档、系统菜单、backlog、TIPS（18:86/87 还是 Skip）、SD 演出。

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
