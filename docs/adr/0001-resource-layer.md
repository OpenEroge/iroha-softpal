# 0001: 资源层（pac / PGD / ARCHIVE.DAT / SYSTEM.INI / 音视频）与 Koikake 的差异

- 状态：Accepted
- 日期：2026-11-09
- 适用范围：`docs/game-profile.md` 里列出的 18 个 `.pac`（按其 SHA-256）；sena-rs `iroha` 分支 `438b4e4`

## 问题

M1：确认 sena-rs 现有的资源层能不能完整读取本作资源，整理与 Koikake 的差异。

## 原生证据 / 测量

复现命令（产物都在 `work/`）：

```bash
for p in iroha_game/*.pac; do n=$(basename $p .pac); \
  sena-rs/target/release/pal-pac-unpacker --input $p --output work/unpacked/$n --overwrite; done
# PGD 批量扫描：对 work/unpacked 下每个 *.PGD 调用
sena-rs/target/release/dump-pgd-info work/isolated-game <NAME>.PGD   # 结果 work/re/m1/pgd-scan.tsv
```

1. **pac**：18 个 pac 全部能列出和解包，exit 0，一共 37,480 个条目，和列表数一致。解密后的魔数：PGD（`PGD3` 24,191 个，`GE␠␀` 2,436 个）、OGG（`OggS`，10,372 个）、MPG（`000001BA`，55 个）、BMP（mask，28 个）、TGA（16 个）、ANI（351 个）、MIX（10 个，`vo0x` 头）。
2. **PGD**：26,627 个全部能被 `dump-pgd-info` 解码（exit 0），**没有不支持的变体**。GE 的 method 只出现 2 和 3；PGD3 是差分图（头里带基底文件名），抽查 `st` 的一张 PGD3，渲染出来正确合成到了基底上（`work/diag/m1/st_pgd3.png`）。
   - 尺寸：立绘 st 是 2048×2048；背景 bk 有 1320×742/743 和 2048×1152 两种；ev/evx 是 1280×720（少量 1280×2048、2048×720 的长图）；face 是 480×300/400。
3. **ARCHIVE.DAT**（在 `data.pac` 里）：不是“三行”，而是**用逗号分隔的三个 profile**（每段末尾带 CRLF），profile 0 = `…|tsubaki|test`，1 = `…|tsubaki|trial`，2 = `…|tsubaki|test`。
   - 脚本只在 `mem_system[52] != 0` 时调用 `set_system_path(mem_system[52])`（`ext 9:44`，两处调用）。默认情况下使用 profile 0，和 sena 启动时选 profile 0 的行为一致。
   - `bgv`、`tsubaki`、`test`、`trial` 这几个 pac 不存在；搜索路径缺失不算错误。
4. **SYSTEM.INI**：真实来源是 **`csv.pac`**（不在 data.pac 里，也没有散放在根目录），Shift-JIS 编码。关键键值：`[graphics] DEF_CG_WIDTH/HEIGHT = 1280×720`（sena 用它作为逻辑分辨率）、`DEF_BK_WIDTH/HEIGHT = 1320×743`；`[initialize] FONT_SIZE=26, DEF_FONT_TYPE=4, DEF_FONT_EFFECT=1`；`[text] ADD_FONTNAME="default_font", EX_FONTNAME="font_ex"`，和 Koikake 一样走 PAL 位图字体路线。
5. **音视频**：
   - movie.pac 里的 LOGO/OPENING：MPEG-PS 封装，**MPEG-1 视频** 1280×720@60；OPENING 带 MP2 48k 立体声。em.pac 里的 53 个 MPG 是 MPEG-1 240×152@48，没有音轨（表情小动画）。
   - BGM/SE/语音全部是 OGG。`BGM.CSV`（循环点）、`SOUND.CSV`、`VO_*.CSV` 都在 csv.pac 里。`.MIX` 是语音混音列表（10 个，在 data.pac）。

## 与 Koikake 的差异（结论）

| 项 | Koikake | 本作 |
|---|---|---|
| ARCHIVE.DAT | 单个 profile | 3 个 profile（逗号分隔），默认用 0 |
| SYSTEM.INI 位置 | 根目录 | `csv.pac` |
| 独有 pac | — | `battle`、`csv`、`tips`、`evx`、`sd` |
| 视频 | MPG/WMV | 只有 MPEG-1 PS |
| PGD | GE + PGD3 | 同样只有 GE（method 2/3）和 PGD3 |

sena 的资源层不需要修改。

## 实现状态

没有代码改动。sena-rs `iroha` 分支的 `0640fb1` 修好了 pal-vm 测试目标的编译问题（与资源层无关，详见 ADR-0002）。

## 运行时验证

- headless 启动：logo 视频（MPEG-1）在第 300 帧左右正常显示，到第 900 帧进入标题（`work/diag/m2/a300.png`、`a900.png`）。
- 音频没有做运行时验证（headless 使用了 `--no-audio`），放到 M3 里随 BGM/SE/语音一起验证。

## 未解决

- BGM.CSV 循环点、`.MIX` 的混音效果，以及 OPENING 的 MP2 音轨是否能正常播放，还没有实测。
- `ANI` 文件（351 个，魔数是 `fc13fdXX`/`fd000000`）的格式还没核对，留到 M3 的 `.ANI` 镜头动画任务。
