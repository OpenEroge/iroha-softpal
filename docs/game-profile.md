# 游戏档案：絆きらめく恋いろは -椿恋歌-

> 本文件只记录**事实与哈希**，绝不粘贴游戏资源内容。新的事实请附上出处（命令或文件）。

## 基本信息

| 项 | 值 | 出处 |
|---|---|---|
| 标题 | 絆きらめく恋いろは -椿恋歌-（汉化名：共结情缘的剑舞恋曲） | `补丁＆附件/存档位置.txt`、汉化说明 |
| 品牌 | CRYSTALiA | 原版存档路径 `我的文档\CRYSTALiA\絆きらめく恋いろは-椿恋歌-` |
| 引擎 | SoftPAL（`dll/Pal.dll`，脚本 `Sv20`） | `SCRIPT.SRC` 魔数 |
| 原版主程序 | `trenka.exe` | — |
| 汉化主程序 | `trenka_cn.exe` + `mai.dll` + `mai/` 覆盖目录（天之圣杯汉化组 V1.0） | `汉化信息及注意事项.txt`（UTF-16LE） |
| 其它 | `config.exe`（设置）、`FileChecker.exe`、`Setup.exe`、`libfusionex.dll` | — |

文本编码：`readme.txt` 是 Shift-JIS，`汉化信息及注意事项.txt` 是 UTF-16LE。阅读时用 `iconv` 转码（`iconv` 对 UTF-16 会自动识别 BOM）。

## 资源层（sena-rs 现状，2026-11-09 测得）

- `ARCHIVE.DAT` 在 `data.pac` 里，共三行（含义未确认，推测分别对应正式版/体验版等配置）：
  - `csv|tips|bgv|movie|bgm|mask|em|evx|ev|sd|etc|bk|se|system|face|voice|st|battle|tsubaki|test`
  - `...|battle|tsubaki|trial`
  - `...|battle|tsubaki|test`
- 安装目录里**没有** `bgv.pac`、`tsubaki.pac`、`test.pac`、`trial.pac`（缺失的搜索路径在 sena-rs 里不算错误）。
- Koikake 没有、本作独有的 pac：`battle.pac`（战斗 UI 的 PGD/OGG）、`csv.pac`、`tips.pac`、`evx.pac`、`sd.pac`。
- `pal-assets <root> paths` / `list-pacs` 能正常解析，`battle.pac` 可以列出文件。
- 脚本：`SCRIPT.SRC` 版本 `Sv20`，entry `0x31C`，points 7085（Koikake 是 entry `0x1F8`、4096 points）。`GRAPHIC.DAT` 有 52 条。
- `data.pac` 里有 368 个文件：大量 `.ANI` 镜头动画、`.MIX` 语音混音列表，以及 `FILE/GRAPHIC/MEM/POINT/TEXT.DAT`、`SCRIPT.SRC`。`SYSTEM.INI` 不在 `data.pac` 里（引擎日志显示它是从 PAL 归档中读到的，具体在哪个 pac 待确认）。

## 汉化覆盖层（M5 才处理）

- `mai/sc/text.mai`（约 0.95MB）：开头是 `$TEXT_LIST__`，和 PAL 的 TEXT.DAT 同一魔数，推测是替换后的 TEXT.DAT（可能还套了一层加密或压缩）。
- `mai/img/*.PGD.mai`：660 个 PGD 替换图，另有 1 个 `TIPSS1056PGD.mai`（文件名少了点号）。
- `mai/chg/`：`LOGO.mpg.mai`、`OPENING.mpg.mai`、`TIPS.CSV.mai`。
- `mai/word.mai`（64KB），用途未知（字体映射或码表？）。
- `mai.dll` 负责在运行时 hook 文件读取；`trenka_cn.exe` 和 `trenka.exe` 大小相同（2776576），可能只改了导入表或字符集。

## 文件指纹

由 `scripts/fingerprint.sh` 生成。逆向结论必须写明适用于哪个哈希。

| File | Size (bytes) | SHA-256 |
|---|---:|---|
| `battle.pac` | 50173457 | `9b01b385fa21fc7785315fdd9918269634bd87eadf1f94b9f6421f914b22098e` |
| `bgm.pac` | 310956082 | `18157602953b5cf87123808d428ea024f977e46c1ae6b086ef734dacc81a957b` |
| `bk.pac` | 491576113 | `c1ee2a57e99a31295c4bf525679cc703c8338d0b0adbb32d429eaa633e78ce50` |
| `config.exe` | 212480 | `016a3c1e79f422b30921d2ea6b96189452513288eace8a2f920d10264a856e41` |
| `csv.pac` | 46198 | `affd634404512931836f2935750aebe7ea238cb416daaa9664e11d517b9f999b` |
| `data.pac` | 4912663 | `90d3463692c021aebd784cb340dcf6a25241feae004c40c9875925c7a90e4a2c` |
| `dll/FX.dll` | 11776 | `46e98ad11e2c43447bcc9faa74afc0893b7e5e8ecd9cbfda733cc6532508d99b` |
| `dll/ogg.dll` | 49152 | `9a3809807c6084eed523156e6b1ff3f806304402633fe445eb31b2076b99170d` |
| `dll/Pal.dll` | 1228288 | `2ef61fc3d6ba354dbb9e3a4da50fe82bc20a4a2e7e0cce401ec51120dc7b8463` |
| `dll/RESOURCE.dll` | 3072 | `af88a84b486ed0676417933b44d366fbd3115f0f47da685b42b91be815145924` |
| `dll/vorbis.dll` | 974848 | `51236e65b58802706b87a2e9bfebeebabb8720bed355bb90444f2e8874058c05` |
| `dll/vorbisfile.dll` | 28672 | `3dbd753fcaad70b15677105dc0ec26c3e38c8e785bf6708301cc5a1286decd32` |
| `em.pac` | 186700246 | `ab68a4593cafdd00737d304d17971c93ec508a9c2ee039c7d703c151d62a4747` |
| `etc.pac` | 81940236 | `8775476f4b6823ad63cad5d5dc76944e29a1f1dc5b09a8c3a26577ccff38fe50` |
| `ev.pac` | 196564316 | `24b3c308aeea8a592ee10043b9626be7806b8c22e1afab3e22e431b56f6f23ce` |
| `evx.pac` | 50562109 | `430415b0df60c2d901ea7fabb2fb636dae59953e0b38fb6aad088b03d0aa50ac` |
| `face.pac` | 121721391 | `b56581ac78945b88e63937a69fa84e1eff6741c6330ae1e0fbf97f40cd57d48f` |
| `FileChecker.exe` | 107520 | `59b5012f0f2e5be0ae1aeb73957915a400c41cc3273a6ff8550053009326c23c` |
| `libfusionex.dll` | 267776 | `bbe38943cc54295bbb7a514b192ff9bdacb6549430c054b2d1d3f71dc4462023` |
| `mai.dll` | 458240 | `7fa6cd925165552e934ae54e3d6fb792f2396a5ce7428a679e8c83600a77f5d6` |
| `mask.pac` | 25837888 | `10ba54f1a0107c978f4a42c32af634ccf6c06f7a7c58bbc3c681dec1d50aad75` |
| `movie.pac` | 195391588 | `ff782d4405335503604da65aaba814abe53eea8eae9f4d54382c70b69c96346f` |
| `sd.pac` | 4641760 | `c7bbff1234c3198bbc8214e191b5252767d98c377704c801eb2ecc53ad214a92` |
| `se.pac` | 159113857 | `2787f0d7f740d2138240db6fec31593ac361810df158cb5bf930a6535bff62b8` |
| `Setup.exe` | 1417216 | `c311f1c4fe35a7b855456d6c901e737c50460def524e5ac5ece235505d64fdea` |
| `st.pac` | 920853052 | `cf9566432e9e2adc735313ace5d12e77b4f57bb419878313b18063b337efa963` |
| `system.pac` | 41648019 | `e81386019588258cb72c5eea59d7459ec0d311dd60e9a831b59a6ea65270ad24` |
| `tips.pac` | 17615011 | `782d98b522194f53b1322846ba2dce40abd93fa8c60ce482d3a4be9170243507` |
| `trenka_cn.exe` | 2776576 | `e22c57606254f23e8cd7e40eba9f60831743de6cf46537a3afcf5272fdd083c6` |
| `trenka.exe` | 2776576 | `1038558f878444ad6bf8964f32651396eefb843a2f138558684b4f718dd109fd` |
| `voice.pac` | 532251274 | `d0eb15c76f3b42636a41003449786d8425d40fa33fe5cf3a875c69bb388f4aad` |
