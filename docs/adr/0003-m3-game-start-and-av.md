# 0003: M3 开局：GAME START、sprite 名查询、SE 播放参数、headless 音频节奏

- 状态：Accepted
- 日期：2026-11-09
- 适用范围：`trenka.exe` sha256=`1038558f…09fd`；`data.pac`（SCRIPT.SRC check `0x5C3077EB`）；sena-rs `iroha` 分支 `dd36acb`、`400a53a`、`5a6d48f`、`1f7fc2a`
- 引擎侧记录：`sena-rs/reverse/iroha-native-profile.md`

## 问题

M3 第一项：从标题点 GAME START，进入游戏并显示第一句台词；文本、立绘、背景、face、BGM/SE/语音都要正常。M2 留下的阻塞是：点 GAME START 后，pc 停在 `0x82490`，画面上出现一个通知框。

## 原生证据 / 脚本证据

1. **pc 0x82490 不是卡死。** `0x82244` 是一个 toast 子程序：显示一个 sprite，`action_sync_run(4500ms)`，然后返回。标题流程在 `0x7FF14` 检查 `mem_system[262] == 0`，满足时调用 `0x824A4`，连续显示 4 条附加内容通知（sprite 3549/3543/3544/3546），结束后置 `mem_system[262] = 1`。这组通知合计约 1100 帧，之前的测试正好在这段时间里结束了，所以误判为卡死。
2. **`sp_get_filename`（3:8，`0x4250B0`）**：sprite 记录位于 `0x655920`，每条 0x274 字节。用字符串加载的 sprite（标志 0x10000000），handler 返回记录 +0x254 处保存的调用者原始字符串。存档恢复（`0x40D0F4`）会把这个字符串原样交给加载函数 `0x447FA0`，而这个加载函数总是在名字后面追加 `.pgd/.mpg/.tga/.bmp` 后缀（表 `0x64CD30`）。因此 +0x254 处保存的是**不带后缀**的名字。
3. **SE 5:2（`0x435A30`）** 弹出 5 个参数，依次是：slot（-1 表示自动找空槽）、name、flags（bit0 循环、bit2 淡入、bit5 声像）、fade_ms，以及一个声音组选择值。选择值用来查表 `0x625FF4 = {5, 4, 6}`。**没有音量参数。** 和 sena 已有的 Totsulover 证据 `0x462990` 一致。
4. **SE 5:1（`0x435D60`）** 只弹 3 个参数（slot、flags、fade_ms），播放一个已经加载好的 slot。而 Koikake 脚本调用 5:1 时压 4 个参数，所以 5:1 的参数个数**因版本而异**。
5. **系统数据持久化**：脚本里只有 4 处调用 `savesystemdata`（10:25），位置是 `0x62680`、`0x6FE60`、`0x77E60`、`0x8051C`。sena 在关闭窗口时不会保存系统数据。

## 结论 / 实现（sena-rs `iroha`）

- `dd36acb`：`sp_get_filename` 返回资源名时，去掉加载器追加的那一个后缀。修复了开场演出中 `sp_get_filename → sp_set` 复制立绘时，去请求 `ST09D_C030.pgd.pgd` 的问题。
- `400a53a`：5:2 按原生顺序解析参数，flags 取 `args[2]`，bit2 时用 `play_fade(args[3])`，`args[4]` 映射到 PAL 声音组，通道音量保持默认值。修改前，sena 把选择值 1 当成了音量 1%，SE 几乎听不见（有效音量 56/10000，约 -45 dB）。5:1 的参数个数因版本而异，这次**不改**。`EXTCALL_CATALOG.md` 按当前 extsig.rs 重新生成（它原本就和源码不同步）。
- `5a6d48f`：新增 `--diagnostic-realtime`。原来的 headless 帧之间从不睡眠（`--diagnostic-frame-ms` 只是 VM 的时间步长，帮助文本写错了），开着设备音频时，VM 时钟远远跑在实际播放的前面。按钮反应要等点击音效 `SYS_BTN_B`（0.35 秒）播完，这个条件永远满足不了，表现为“开音频后 GAME START 点不进去”。这是测试方法的问题，窗口模式下不会出现。外层 `scripts/headless.sh` 新增 `HEADLESS_AUDIO=1` 开关，开启后自动加上这个参数。
- 每次启动都会重新显示附加内容通知：这是因为没有走到保存点就结束了运行（headless 被直接终止）。窗口模式下关闭窗口，sena 同样不会保存，这一点待处理（见“未解决”）。

## 运行时验证

- `scripts/headless.sh 8000 --diagnostic-auto-advance --diagnostic-auto-advance-min-frames 90 --diagnostic-click-when-hit-enabled 280:184 --diagnostic-png-at …`：第 3600 帧出现第一句台词（背景、立绘、名字框、VOICE 图标），后续出现事件 CG 和 face 小头像，`sprite resource not found` 已经消失。截图在 `work/diag/m3/r*.png`、`sheet.png`。
- `HEADLESS_AUDIO=1` 等价的实时运行（3400 帧，第 2500 帧点击）：能进入游戏，`[trace-audio]` 中依次 play 了 BGM08、vo_system17/19、VO02/VO09 台词语音、SE07/SE99。SE 的有效音量从 56 变为 5600，SE99（flags=5）走淡入路径。**没有人耳实际听过**。
- 30000 帧 auto-advance：剧情一直在推进，没有卡住；OPENING.MPG 播放了 124 秒，其中第 35.5 秒附近的“花屏”画面经 ffmpeg 解码对照，确认是 OP 本身的故障风特效。
- 测试：pal-vm lib 250 个通过；集成测试只有两个基线就失败的用例（`nls_config_fixture`、`operand_fixture::high_frequency…`）。

## 未解决

- `.ANI` 字节码（`ANI_LINE_EFFECT*`、`ANI_SYM_ASERI` 等）只支持单条指令的简单形式，多指令的会被报为 unsupported。开场的 letterbox 线条动画因此没有过渡效果。这对应 roadmap M3 的 `.ANI` 项。
- 5:1 在非扩展版本中一律弹 5 个参数；本作压 3 个（共 22 处调用），执行到时会造成栈错位。需要按版本确定参数个数的机制。
- 关闭窗口时不保存系统数据；原生在退出时是否保存 system.dat 需要逆向确认。
- 常见的 Skip：18:86/87（tips 标志，每帧调用）、5:8 `channel_error_set_se_info`、17:35、18:108。
- 音频需要开窗口，由人工实际听一遍确认。
