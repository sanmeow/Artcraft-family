# 各 Craft CLI 用法速查

以下內容整理自各 repo 的原始碼（版本：2026-10）。**以實際執行 `<app>-cli --help` 的結果為準**，新版的參數可能有變動。

所有工具都採用相同模式：每個功能都是一個**命令 ID**，加上 JSON 參數。查詢命令的方式：

| App | 列出命令 | 單一命令說明 |
|---|---|---|
| PhotoCraft | `photocraft-cli commands` | `photocraft-cli commands`（含參數說明） |
| EffectCraft | `effectcraft-cli commands --filter TEXT` | `effectcraft-cli exec --list` |
| FilmCraft | `filmcraft-cli commands [filter]` | `filmcraft-cli describe <id>` |
| VectorCraft | `vectorcraft-cli commands`（JSON） | |
| LightCraft | `lightcraft-cli run engine.commands` | |
| PdfCraft | `pdfcraft-cli tools`（含 JSON Schema） | |
| DesignCraft | `designcraft-cli commands [FILTER]` | `designcraft-cli describe COMMAND` |

每個工具也都有 `mcp` 子命令，可以當作 MCP 伺服器讓代理直接呼叫。用 `--automation-read-root` / `--automation-write-root`（PdfCraft 用 `--root`）可以把讀寫範圍限制在指定資料夾。

---

## PhotoCraft（Photoshop）：`photocraft-cli` ⭐

| 子命令 | 用途 |
|---|---|
| `info <file>` | 以 JSON 輸出尺寸、色彩模式、bit depth、圖層資訊（`--compact` 精簡版，含缺字型警告） |
| `convert <in> <out> [--format ext] [--quality 1-100]` | 轉檔 |
| `run (<file> \| --new <json>) --cmd <id> [--params <json>] … [--out <file>]` | 開檔或新建文件，依序執行命令後存檔 |
| `batch --actions <a.json\|set.atn> [--action 名稱] --in <dir> --out <dir> [--format ext] [--quality N]` | 對整個資料夾套用同一份 action，也可以讀 Photoshop 的 `.atn` |
| `droplet` | 執行 PhotoCraft droplet |
| `commands` | 列出 500+ 個命令 ID 與參數 |
| `mcp` | MCP 伺服器（stdio） |
| `serve` | JSON-lines 伺服器（stdio 或本機 TCP） |

Action 檔格式：`[["命令ID", {參數}], …]` 的陣列，也可以包成 `{"steps": […]}`。

支援格式：PSD/PSB、分層 TIFF、`.pcraft`、OpenRaster、Krita `.kra`（唯讀）、Paint.NET（唯讀）、Affinity（唯讀）、SVG、PNG、JPEG、WebP、GIF、BMP、TGA、ICO、QOI、PNM、EXR、HDR、FITS、HEIC（唯讀）。

---

## EffectCraft（After Effects）：`effectcraft-cli`

專案檔是 `.ecproj`。用 `--project F.ecproj` 開啟，`--save` 或 `--save-as F` 存檔。

| 子命令 | 用途 |
|---|---|
| `info` | 專案與引擎摘要 |
| `exec <command-id> [--params JSON]` / `run <id> <json> …` | 執行一個或多個命令 |
| `props <comp> <layer>` | 圖層的屬性樹（含路徑） |
| `get` / `set <comp> <layer> <path> <value> [--time S] [--expression E]` | 讀寫屬性和關鍵影格 |
| `render-frame [--comp C] [--time S] --out F.png` | 算一張畫格 |
| `render [--comp C] --out FILE [--format h264\|hevc\|av1\|prores\|webm\|png\|gif…]` | 算圖成影片或圖片序列 |
| `render --template T.ectemplate --values V.json` | 範本化產出（例如批次換字） |
| `script FILE.jsx` | 用 After Effects 風格的 JavaScript 物件模型寫腳本 |

例子：`effectcraft-cli set Main '#1' transform/position '[100,360]' --time 0 --project main.ecproj --save`

---

## FilmCraft（Premiere Pro）：`filmcraft-cli`

`--project p.fcproj` 開啟專案。主要子命令：`exec`、`run script.jsonl`、`inspect`、`import`、`export <out> [--preset|--format h264…]`、`render --seconds S --out f.png`、`probe <media>`。不需要 FFmpeg。

---

## VectorCraft（Illustrator）：`vectorcraft-cli`

- `convert IN OUT`：向量格式互轉（SVG、PDF、EPS、AI、PSD、PNG…），可以用 `--artboard` 選工作區域、`--outline-text` 把文字轉外框。
- `run [--in FILE] [--cmd ID [--params JSON]]… [--export FILE]… [--scale N]`
- `info FILE`、`commands`

---

## LightCraft（Lightroom）：`lightcraft-cli`

- `render <IN> -o <OUT> [--set light.exposure=0.5] [--settings F] [--preset ID] [--size 長邊px] [--quality Q] [--opt ppi=300]`：顯影並匯出單張照片（也支援 RAW）
- `run --import <路徑> <命令> key=value …`：批次操作
- `mcp`

---

## PdfCraft（Acrobat）：`pdfcraft-cli`

- `tools`：列出所有工具及其 JSON Schema
- `run <tool> key=value …` 或 `run --script steps.json [--root DIR] [--report]`
- 功能包括開檔、算圖成 PNG、搜尋或擷取文字、旋轉、刪除、搬移、插入頁面、書籤、註解、表單、密碼、合併、拆分

---

## DesignCraft（InDesign）：`designcraft-cli`

- `run [--in FILE] [--cmd ID[=JSON]]… [--export OUT.pdf|.png|.idml|.epub|.pptx] [--all-pages DIR]`
- `script FILE [--in FILE] [--save OUT] [--export OUT]`：一行一個命令，可以用 `$N.path` 引用前面步驟的結果
- 支援讀取 `.idml`
