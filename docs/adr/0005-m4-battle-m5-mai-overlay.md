# 0005: M4 战斗演出的归属；M5 mai 汉化覆盖层

- 状态：Accepted
- 日期：2026-11-10
- 适用范围：
  - `trenka.exe` sha256=`1038558f878444ad6bf8964f32651396eefb843a2f138558684b4f718dd109fd`
  - `trenka_cn.exe` sha256=`e22c57606254f23e8cd7e40eba9f60831743de6cf46537a3afcf5272fdd083c6`
  - `mai.dll` sha256=`7fa6cd925165552e934ae54e3d6fb792f2396a5ce7428a679e8c83600a77f5d6`
  - `battle.pac` sha256=`9b01b385fa21fc7785315fdd9918269634bd87eadf1f94b9f6421f914b22098e`
  - `iroha_game/mai/` 目录

## 问题

1. M4：`battle.pac`（战斗用的 PGD/OGG）的逻辑在脚本里，还是在 exe 里？如果在 exe 里，需要逆向哪些专用 extcall？
2. M5：汉化补丁 `mai.dll` + `mai/` 挂钩了什么，`.mai` 文件是什么格式，`word.mai` 有什么用？怎样在 sena-rs 里实现等价的覆盖层？

## 原生证据

### M4 战斗

- `battle.pac` 有 253 个条目：
  - `SLASH_*`：斩击 cut-in
  - `BATTLE_*`：底图和部件
  - `VIEWCHANGE_*`：视角切换线
  - `BA_FREESIA_WINDOW_*`
  - `SE99_BA_*`：战斗音效
- `trenka.exe` 的字符串里没有任何战斗资源名。这些名字只出现在 `FILE.DAT` 里，共 185 处，索引在 83..3553 之间。
- 脚本里用到这些索引的地方分两类：
  - 战斗演出函数，集中在脚本地址 `0xB9000–0xDE000`（point 6175–6672）
  - 各章节剧本里的 SE 调用
- 这段区域只用到这些通用 extcall：
  - `sp_set_ex`（424 次）
  - action 类：`alpha_delta`、`position_sine`、`scale_curve`、`shake`…
  - `se_play_ex_ch`
  - `random`、`wait`
- 区域里没有设置按钮或等待输入的调用（只有收尾时的 `btn_release` / `btn_uninit`）。战斗是**非交互的脚本演出**，没有 exe 内置的战斗子系统。
- 这些 extcall 都在 M3 审计过的 419 个坐标之内，弹栈个数与原生一致（ADR-0004 第 9 节）。

### M5 mai.dll

地址以 `mai.dll` 映像基址 0x10000000 为准。

- `trenka_cn.exe` 与 `trenka.exe` 逐字节比较只有 13 字节不同：导入表里的 `COMDLG32.dll!GetSaveFileNameA` 换成了 `mai.dll!MetSaveFileNameA`。`mai.dll` 转发这个函数和 IMM32 的 `ImmAssociateContext`，其余功能全在 `DllMain`（0x10001080）里挂钩完成。
- `LoadLibraryExA` 被挂到 0x10004020。PAL.DLL 加载时，它挂钩以下函数：
  - `PalFileCreateEx` → 0x10003B40：如果 `<exe 目录>\mai\chg\<文件名>.mai` 存在，就改为打开它。
  - `PalSpriteLoad` → 0x100038A0：原函数加载成功后，用 `libfusionex.dll` 解码 `mai\img\<名>.mai`（PNG），再按 PNG 的宽×高×4 字节 `memcpy` 到锁定的纹理上。原 sprite 的位置和偏移不变，前提是两张图尺寸相同。
  - `PalFontSetType` → 0x10003880：类型 4（位图字体）改成 1。
  - exe 的文本记录读取函数（`exe+0x4B470`）→ 0x10003F60：先调用原函数，再用 `mai\sc\text.mai` 里**同一记录 id** 的记录覆盖结果。id 0–4 不覆盖，这几条是 GDI 字体名。
  - 启动时把磁盘上的 `movie` 目录改名为 `movies`。这只是安装时的副作用，与引擎无关。
- 另外两个挂钩：
  - `CreateFontA` → 0x10004580：字体名强制为 `SimHei`（竖排为 `@SimHei`），字符集强制为 `GB2312_CHARSET`（0x86）。
  - `GetGlyphOutlineA`：先用下面的码表把编码转成 UTF-16，再调用 `GetGlyphOutlineW`。
- `text.mai`：`$TEXT_LIST__` 表，从 0x10 起的加密方式与 TEXT.DAT 相同（rol 4,5,6,7,0… 再 XOR `0xF7D5859D`，见 0x10003EB6），共 25,793 条。`chg/`、`img/` 下是不加密的 CSV / MPEG-PS / PNG。
- `word.mai`：65536 字节，按 UTF-16 码位记录“译文是否用到这个字符”，非 ASCII 的有 2,996 个。码表在 0x10004220 / 0x100041C0 生成：
  1. 候选码位：首字节 0x81–0x9F、0xE0–0xEF；次字节 0x40–0x7E、0x80–0x9E、0xA0–0xFC，**不含 0x9F**；再去掉 0x889F 以下（非汉字区）。
  2. 被标记的字符如果 cp932 能编码，就保留它的规范码（0x1003F120 的表：解码成该字符的最大码位，不算 0xF0–0xF9 外字区），并把这个码位移出候选。
  3. 其余被标记的字符按码位升序，依次占用剩下候选里最小的码位。
  4. 显示时只对双字节码位做反查，其它字节一律显示为 `?`。
- 结论：译文**不是 GBK**，而是借用 Shift-JIS 字节结构的“伪 SJIS”。roadmap 里“处理 GBK 文本”这一项实际要处理的是这种码表。

## 决策 / 结论

- M4：不需要任何战斗专用 extcall 或 VM 特判。战斗演出完全由脚本通过通用 extcall 驱动，引擎侧的工作已经包含在 M3 的 extcall 审计和实现里。
- M5：在 sena-rs 里实现为可选的覆盖层，由 `--patch mai` 打开，读取 `<游戏根>/mai`。原版和补丁共用同一套引擎代码路径，不按游戏名分叉。
  - 码表在运行时由 `word.mai` 加 encoding_rs 的 cp932 解码重新生成，**不拷贝** DLL 里的数据表。
  - 补丁没有分配的码位回退到普通 cp932 解码，比原生显示 `?` 更稳妥（旧存档里的日文、id 0–4 的记录都能正常显示）。
  - 尺寸不符的替换图不做 `memcpy`，原生那样会越界；保留原图并记录警告。
  - SimHei 用宿主系统字体代替，按候选列表找（macOS 的 STHeiti / Hiragino Sans GB，Linux 的文泉驿 / Noto CJK，Windows 的 simhei）。`--font-file` 或游戏 `fonts/` 目录里的字体优先。

## 实现状态

sena-rs `iroha` 分支：
- `crates/pal-asset/src/mai.rs`：`MaiCharset`、`MaiText`、`MaiPatch`。`Nls::Mai(&'static MaiCharset)` 让所有按 NLS 编解码的路径（脚本字符串、CSV、存档、字体）自动使用补丁码表。
- `ResourceManager::set_mai_patch`：`chg` 文件优先于所有搜索路径。`replacement_image` 读取 `img`；名字没有后缀时也匹配 `<名>.PGD.mai`。
- `CoreAssets::apply_text_patch` / `TextPatch`：按原 Text.dat 记录的偏移（只认真正的记录起点）映射到补丁里同 id 的记录。`resolve_script_string` / `resolve_resource_string` 统一走 `text_dat_record`。
- `decode_asset_image` → `apply_replacement_pixels`：尺寸相同才替换像素。
- `PalFontSystem::set_outline_text_only`：类型 4 → 1。`ScriptRuntime::apply_translation_font_policy` 选择字体，`SIMHEI_SUBSTITUTE_CANDIDATES` 是候选列表。
- `TranslationPatch` / `--patch mai`：`Engine::new` 在读取任何资源之前，把 `nls` 换成补丁码表。
- 英文文档：`reverse/mai-translation-patch.md`。

## 运行时验证

- 码表：把 0x10004220 的算法用 DLL 自带的表在 Python 里模拟，与 Rust 生成的结果对比，2,996 个字符全部一致（临时程序在 scratchpad，没有提交）。
- 补丁加载日志：3 个 chg 文件、661 张图、25,793 条文本；替换了 Text.dat 的 25,788 条（id 0–4 保留）。
- 替换图：655 张与原图尺寸一致；`TIPSS0021`、`TIPSS0048` 两张尺寸不符，保留原图；另有 4 张找不到原图。
- headless 截图（`work/diag/m5/`，用 Read 查看过）：
  - 启动画面是补丁的 CAUTION 图（汉化组 staff）；`movie sprite "LOGO.mpg" from .../mai/chg/LOGO.mpg.mai`
  - 标题画面（`title.png`）
  - ADV 正文和名字框是简体中文，字体是 STHeiti（`a2400.png`、`a12000.png`）
  - SYSTEM 画面：替换图和运行时绘制的下拉框文字都是中文（`sysmenu.png`）
  - 收藏语音画面的按钮图（`tips_b.png`）
  - 游戏内 TIPS：`TIPS.CSV.mai` 读到 272 条，词条高亮，小窗口里的标题和说明都是中文，含 ②（`ctw2.png`，空存档，第 26760 帧）
  - 存档：空存档下存到第 1 格，确认框和存档格里的台词摘要都是中文。说明中文经 `Nls::Mai` 编码写入存档，再解码读出，结果正确（`save3.png`、`save4.png`）
- M4：
  - 2,300,000 帧整线自动推进，在战斗脚本区间（`0xB9000–0xDE000`）停留了 14,137 帧，没有 unimplemented，没有 panic（`work/diag/m4/route_*.txt`）
  - 第 467200–469000 帧逐 40 帧截图，可以看到 “Aoi's view” 视角切换、集中线 cut-in、刀光 sprite、角色滑入，以及带头像的文本框（`work/diag/m4/seq_a.png`）
  - 第 1068680 帧附近同屏出现两个造型相同的角色：脚本在这里分别设置了 `ST07E_B010` 和 `ST21A_A010` 两个不同的立绘，是有意的演出，不是残留的 sprite
    - 更正（2026-11-10，见 ADR-0007）：18:3 的语义错误会把表情切换送进错误的槽位，造成同一角色出现两次。上面的结论是在修复之前得出的，需要在修复后复查。
- 回归：`cargo test -p pal-vm -p pal-script -p pal-asset -p pal-disassembled` 全部通过；`cargo check --workspace --all-targets` 没有错误。不加 `--patch` 时代码路径与原来相同。

## 未解决

- 没有原生 Windows 截图可以对照，所以中文字形（STHeiti 与 SimHei 的差别）和战斗演出的细节只做了合理性检查。
- 汉化补丁的说明文件里写有“严禁拆解、二次修改、移植应用于任何平台”。本仓库不分发、不修改补丁文件，只在运行时读取用户本地的副本；文档里只记录文件名、偏移、哈希和数量。是否在发布说明里提到这一点，由用户决定。
