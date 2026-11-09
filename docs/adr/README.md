# ADR（架构 / 逆向决策记录）

- 文件名：`NNNN-短标题.md`，从 `0000-template.md` 复制。
- 每个 ADR 都要写明**适用范围**：哪个二进制（文件名 + SHA-256，见 `docs/game-profile.md`）、哪个 pac 或资源。
- 把“原生证据”、“实现状态”、“运行时验证”分成三节写，不要混在一起。
- 已接受（Accepted）的 ADR 不要重复去逆向。只有出现具体矛盾、二进制不同或证据有缺陷时，才重开，并新写一个 ADR 来 supersede 它。
- 与引擎通用语义有关的结论（PAL ABI、extcall 契约）还必须按 `sena-rs/AGENTS.md` 的要求，同步写进 `sena-rs/reverse/abi/*.json` 等位置；这里的 ADR 负责链接过去。
- 语言：本目录的 ADR 可以用中文。sena-rs 内的文档、代码、注释一律用英文。

| # | 标题 | 状态 |
|---|---|---|
| 0001 | [资源层与 Koikake 的差异](0001-resource-layer.md) | Accepted |
| 0002 | [trenka/Pal.dll 原生接口、extcall 覆盖与 gosub 操作数](0002-native-interface-and-extcalls.md) | Accepted / Proposed（未实现的 extcall） |
| 0003 | [M3 开局：GAME START、sprite 名查询、SE 参数、headless 音频节奏](0003-m3-game-start-and-av.md) | Accepted |
| 0004 | [M3 原生子系统：版本识别、ANI、action 扩展、存档标签、TIPS](0004-m3-native-subsystems.md) | Accepted / Proposed（收藏语音等） |
