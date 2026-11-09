# 0007: 立绘表情切换的槽位查找（trenka 的 18:3）

- 状态：Accepted
- 日期：2026-11-10
- 适用范围：`trenka.exe` sha256=`1038558f878444ad6bf8964f32651396eefb843a2f138558684b4f718dd109fd`；脚本里的 point 311、320、393

## 问题

用户截图：同一角色同屏出现两次，左边一个是旧表情，右边一个是新表情。复现位置：脚本 0x195FB0 附近（自动推进约第 440,000 帧）。用户截图里的台词是 TEXT 记录 10836。

## 原生证据

- 表情切换宏 point 393 的流程：
  1. point 311 把立绘文件 id 映射成角色编号：对 i=0..39，用 `file_string(memdat[185+i], memdat[282+i])` 生成前缀（如 `ST09`），再用 18:3 判断文件名里是否包含这个前缀。
  2. point 320 读取该角色的槽位：`mem_user[190 + 角色]`。
  3. 对这个槽位调用 `sp_set_transition(槽位, 文件, 1, 300)`。
- trenka 的 18:3（0x41B050）：
  - 依次弹出 haystack 和 needle，两者都经 0x44B500 解析：动态字符串，否则取 File.dat 条目（`index*32+0x10`）。
  - 两个字符串都转成大写，然后调用 CRT `strstr`（0x484750）。找到返回 1，否则返回 0。
  - 这和 Game.exe 的 18:3（不相等测试）不同。

## sena-rs 原来的偏差

本作沿用了 Game.exe 的语义：按 Text.dat 解析操作数，并判断“不相等”。结果每个立绘文件都被认成角色 0，表情切换落到了角色 0 的槽位上：
- 如果那个槽位里有别的立绘（比如刚退场的角色），它会被替换成这个角色的新表情，而原槽位里的旧表情保留下来，于是同一角色出现两次。
- 如果那个槽位是空的，就会出现 “no current image” 警告。

## 决策 / 实现

sena-rs `iroha` 分支：
- 在 `trenka_wrappers.rs` 加入 `ext_string_contains_ignore_case`，并把 (18, 3) 加入 `TRENKA_OWN_EXTCALLS`。
- Game.exe 的路径不变。
- 测试：`string_test_is_a_case_insensitive_substring_search`。

## 运行时验证

- 修复前，450,000 帧自动推进（`--patch mai`）中出现 9 次 “no current image”；修复后为 0，也没有 unimplemented。
- 0x195FB0 场景的截图：`work/diag/twin/grid.png`（修复前）、`grid3.png`（修复后）。
- ADR-0005 里第 1068680 帧附近“两个造型相同的角色是有意演出”的结论是在这次修复之前做的，需要复查。
