# 0006: ADV 右侧菜单由脚本线程驱动

- 状态：Accepted
- 日期：2026-11-10
- 适用范围：
  - `trenka.exe` sha256=`1038558f878444ad6bf8964f32651396eefb843a2f138558684b4f718dd109fd`
  - `data.pac` 里的脚本（point 2367、2881、2903 及 ADV 初始化 0x50934 起）
  - 与 `--patch mai` 无关：原版同样出问题

## 问题

用户在汉化版里点 ADV 画面右下角的 `>>`，弹出的 MENU 面板是空的：只有底板和一个“快速存档”提示框，按钮全部看不见。不加补丁也一样。

## 原生证据

- **菜单是脚本做的，不是 exe**。按钮 `MAIN_BTN_*` 都在 group 0：1 是面板底板，22 是 `>>`，2..18 是面板上的按钮。打开和关闭由脚本线程 point 2367 完成。这个线程在 0x42670 由 `create_thread` 创建，条件是 `mem_system[134]`：
  - 每帧读鼠标位置（9:12），判断是否在面板区域内。
  - 进入区域并且菜单关着：隐藏 `>>`，按钮 `i` 用 lane `2*i` 淡入、lane `2*i+1` 向左移动一个面板宽度（215），然后 `mem_user[0]=1`。
  - 离开区域并且 `mem_user[0]==1`：反向滑出。
  - 点击 `>>` 的回调 point 2903 只有在触屏模式（`mem_system[163]`，由 `is_touch` 和 INI 决定）下才调用 point 2881 打开菜单。鼠标模式下点击 `>>` 不起作用，靠悬停打开。
  - ADV 初始化（0x5095C，`mem_system[33]==0` 时）对每个面板按钮执行 `sp_set_pos_move(0x02000000|i, 215, 0, 0)`，先把它们移到屏幕右侧之外。
- **线程不是协程**：
  - `create_thread`（0x42F300）只记录目标 point，并置 active/running（+0x4D2324、+0x4D2328）。
  - 调度点（0x42F1E0，以及等待处理里的 0x445629）在 running 并且没有进行中的调用（+0x4D232C）时，压入一个 type 3 调用帧去执行该 point。对应的 `ret`（0x42D643）只把进行中计数减一。
  - 所以线程函数每次 `ret` 以后，下一次调度会再调用它；主脚本在等点击时也照样调度。唯一的例外是有 action bank 处于 `action_sync_run`（0x4455D9 分支）。
- **action 表大小**：
  - `set_active_action`（0x408F90）接受 bank 0..15。
  - `action_alpha_delta`（0x409F40）等接受 line 0..63，每条 line 最多 64 段。
  - 超出时直接返回，不弹剩下的参数。菜单用到的 lane 最大是 47。
- **`sp_set_pos_move`（0x428F20）**：用 0x449110 解析槽位，这个函数也能把打包的按钮槽位 `0x02000000|index` 解析成按钮 sprite，然后把位移加到 wrapper 的基准位置上。
- **15:8**（0x411B50）：把 VM 栈深度写进目标槽位，不弹参数。只在菜单线程的调试输出里用到。

## sena-rs 原来的偏差

1. 线程第一次 `ret` 就被永久停掉；主脚本在等待时也不运行线程；每帧最多执行 64 条指令。结果 point 2367 只在开头跑一次就退出，悬停没有任何反应。
2. 为 Koikake 写的宿主端“ADV 菜单模拟”：按名字匹配 `MAIN_BTN_BASE0/1`，拦截对 `>>` 的点击，自己切换显示状态，并把 Q.SAVE/Q.LOAD 的 alpha 跟随其他按钮。它绕开了脚本，只显示了底板，按钮因为 alpha 是 0 而看不见，这就是用户截图里的样子。`btn_enable(false)` 还会把按钮隐藏，可面板底板本来就是一个 disabled 但需要显示的按钮。
3. 本作使用 Koikake 的 action 表大小（8 个 bank × 32 条 line）。`set_active_action(8)` 和 lane 32 以上全部失败，没弹出的参数堆积在主脚本栈上。
4. 只有 registered 构建的 `sp_set_pos_move` 支持打包的按钮槽位，所以初始化时按钮没有被移出屏幕，滑入以后位置偏左 215。

## 决策 / 实现

sena-rs `iroha` 分支：
- `run_thread_slice`：线程函数返回后，按 `target_point` 重新解析入口，下一帧再进入；suspend 后再 resume，也从入口开始。`run_script_thread` 在主脚本 `WaitClick` / `WaitFrame` 时也执行，有 bank 处于 sync run 时跳过。线程使用和主脚本相同的指令预算。存档检查点格式不变。
- 删除 `adv_menu_expanded`、`adv_menu_bases`、点击拦截和 Q.SAVE/Q.LOAD 的 alpha 跟随。group 0 按钮只跟随文本窗口和自身的 show/hide 状态。Koikake 的 `btn_expansion` 特判（index 14）改为显式设置 `visible=false`，保持原来隐藏 VOICE 弹出条的效果。
- `NativeBuild::wide_action_tables()`：trenka 使用 16×64×64 的 action 表，和 `extended` 的分辨率缩放、跳过掩码互不影响。
- `NativeBuild::sprite_slots_resolve_buttons()`：trenka 的 3:25 也能移动打包的按钮槽位。
- 15:8 加入 `TRENKA_OWN_EXTCALLS`，返回栈深度。
- 英文文档：`reverse/iroha-native-profile.md`。

## 运行时验证

- headless（`work/diag/m5menu/`）。鼠标位置靠 `--diagnostic-click` 或 `--diagnostic-auto-advance-click` 移动：
  - 鼠标在区域外时只显示 `>>`（`e0.png`）。
  - 移到面板上，所有按钮滑入到正确位置：BACK/NEXT、SAVE/LOAD、Q.SAVE/Q.LOAD、AUTO/SKIP、LOG/SYSTEM、CLOSE/HOLD、FAVORITE、窗口透明度滑条，同时 `>>` 隐藏（`e1.png`、`grid_h.png`）。
  - 移开后滑出，`>>` 恢复（`e2.png`）。
  - 加 `--patch mai` 时：点 Q.SAVE 会写入 `save999.dat`；点 SYSTEM 会打开中文的 SYSTEM 画面（`grid_c.png`）。
- 测试：
  - `script_thread_reenters_every_frame_even_while_main_waits`
  - `adv_toolbar_follows_text_window_and_show_state_only`
  - pal-vm lib 共 285 个测试全部通过，pal-script、pal-asset、pal-disassembled 也全部通过。
- 剧情回归：200,000 帧自动推进，没有 unimplemented，没有 panic。标题画面在新旧二进制下、相同输入时逐帧截图一致。

## 未解决

- 删除的宿主端菜单模拟原本是为 Koikake 写的。Game.exe 的线程结构和这里相同（`reverse/ENGINE_CONTEXT_RE.md` Region 15 里同样有 active/running/in-flight/target/id），所以 Koikake 应该也由脚本线程驱动菜单。但本机没有 Koikake 资源，无法做运行时验证，只跑了已有的单元测试。
