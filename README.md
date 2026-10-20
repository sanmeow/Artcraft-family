# Artcraft-family

用 [ArtCraft](https://getartcraft.com/) 的「Crafting Apps」命令列工具（CLI），讓 Claude 等 AI 代理在雲端 VM 裡，依照文字說明完成影像或設計的編修任務。

這個 repo **以 [PhotoCraft](https://github.com/storytold/photocraft) 為首**。PhotoCraft 是開源、純 Rust 的 Photoshop 重新實作，可以讀寫 PSD/PSB。其他 Craft 工具也可以依任務需要隨時安裝。

> 這裡不放任何工具本體。CLI 一律在需要時用 `setup/install.sh` 下載**最新版**，見[環境初始化](#環境初始化)。

---

## 這個 repo 做什麼

**使用情境：** 手邊沒有電腦，或不想在主電腦上安裝環境時，在 claude.ai 網頁版上傳素材、用文字描述需求，由雲端的 Claude 使用這裡準備好的 CLI 完成編修，再把成品傳回來。平常在自己電腦上試出可行的 CLI 做法後，記錄到 `docs/recipes.md` 或 `scripts/`，之後就能直接重複使用，不必每次從零開發工具。

1. 你在 `tasks/` 寫一份任務說明（目標、輸入、輸出規格），素材放進同一個資料夾的 `in/`。
2. 代理（例如 Claude Code）讀任務、安裝需要的 CLI、執行編修。如果是批次任務，就整個資料夾一起處理。
3. 成品寫到 `out/`，並附一份 `REPORT.md` 說明做了什麼、怎麼做的、有沒有問題。之後提交並推送回 GitHub，你就能拿到結果。

常見任務例子：

- 一組圖包全部轉成 **A4**（300 dpi，2480×3508 px），等比縮放後置中留白，或裁切填滿。
- 批次修改 PSD：替換文字圖層、套調整圖層、匯出成 PNG/JPG。
- 把 PSD 的每個圖層或工作區域（artboard）分別匯出。
- 統一調色：套 LUT（.cube）、Curves、Levels，或匯出調色結果成 LUT。
- 動態圖像（After Effects 類）：修改專案中的文字或關鍵影格，算圖成 MP4 或 Lottie。
- PDF：合併、拆分、旋轉、加密、填表單。

---

## 工具一覽（Crafting Apps）

| App | 對應的 Adobe 工作流程 | CLI | 用途 | 優先度 |
|---|---|---|---|---|
| **[PhotoCraft](https://github.com/storytold/photocraft)** | Photoshop | `photocraft-cli` | 點陣影像、PSD/PSB、圖層、調整圖層、濾鏡、批次 action | ⭐ 主要 |
| [EffectCraft](https://github.com/storytold/effectcraft) | After Effects | `effectcraft-cli` | 動態圖像、合成、關鍵影格、算圖成影片、Lottie | 需要時 |
| [FilmCraft](https://github.com/storytold/filmcraft) | Premiere Pro | `filmcraft-cli` | 影片剪輯、調色、聲音、字幕 | 需要時 |
| [VectorCraft](https://github.com/storytold/vectorcraft) | Illustrator | `vectorcraft-cli` | 向量插畫、SVG | 需要時 |
| [LightCraft](https://github.com/storytold/lightcraft) | Lightroom | `lightcraft-cli` | 照片庫、RAW 顯影、批次調色匯出 | 需要時 |
| [PdfCraft](https://github.com/storytold/pdfcraft) | Acrobat | `pdfcraft-cli` | PDF 合併、拆分、頁面、註解、表單、密碼 | 需要時 |
| [DesignCraft](https://github.com/storytold/designcraft) | InDesign | `designcraft-cli` | 版面編排、出版 | 需要時 |
| [SoundCraft](https://github.com/storytold/soundcraft) | Audition | `soundcraft-cli` | 錄音、音訊剪輯與混音（DAW） | 需要時 |

這些工具共用同一套設計：介面上的每個選單項目都是一個有 ID 的**命令**，CLI、JSON 控制通道和 MCP 伺服器都呼叫同一批命令。所以 GUI 做得到的事，CLI 原則上也做得到。各工具的命令清單用 `<app>-cli commands`（PdfCraft 是 `pdfcraft-cli tools`）查詢。

> ⚠️ 這些工具都還在 **early alpha**，功能和行為可能有落差。每次任務都要檢查輸出結果，不要只看指令有沒有回報成功。

---

## 環境初始化

### 需求

- Linux（x86_64 或 aarch64）、`bash`、`git`、`curl`、`tar`。`install.sh` 下載的是 Linux 版。在自己的 Mac 或 Windows 上，請從各 app 的 GitHub Releases 手動安裝（例如 macOS 的 `photocraft-cli-<ver>-macos-universal.zip`）
- 只有在無法下載 release 時才需要 Rust 1.95 以上（[rustup](https://rustup.rs)），用來從原始碼編譯

### 安裝

```sh
./setup/install.sh                  # 只裝 PhotoCraft（預設）
./setup/install.sh effectcraft      # 需要時再加裝其他工具
./setup/install.sh all              # 全部裝
source setup/env.sh                 # 把 .craft/bin 加進 PATH
./setup/status.sh                   # 查看已裝版本與最新版本
```

- 預設 `--method auto`：先下載 GitHub Release 的 Linux tarball（內含 `<app>-cli`），用 `SHA256SUMS.txt` 驗證後只保留 CLI 執行檔。只有下載失敗時，才改成 `git clone` 最新的 release tag 並用 `cargo build --release -p <app>-cli` 編譯（需要 Rust）。
- 最新版本由 `git ls-remote --tags` 取得，不需要 GitHub API。
- `--update`：有新版才重新安裝。沒加這個參數時，已安裝的工具不會更動。
- `--method release` / `--method source`：只用其中一種方式。
- 安裝位置是 `.craft/`（不進版控，全部 CLI 共約 500 MB 以上），可以用 `CRAFT_HOME` 改位置。

### 在 Claude Code 雲端環境（claude.ai/code）

已實測：雲端 VM 可以直接下載 release，7 個 CLI 全部安裝約 30 秒（SoundCraft 是後來加入的，還沒有實際測試），不需要編譯。雲端 VM 每次工作階段都是全新的，所以每個新工作階段開始時都要重新執行 `./setup/install.sh`（代理會依 `CLAUDE.md` 自動執行）。

---

## 怎麼下任務

1. 複製 `tasks/_template/`，改名成 `tasks/<日期>-<簡短名稱>/`，例如 `tasks/2026-10-18-a4-poster-pack/`。
2. 填寫 `TASK.md`：目標、輸入、輸出規格（尺寸、格式、色彩、命名）、驗收標準。
3. 把素材放進 `in/`。如果檔案很大，可以改寫素材的下載位置。
4. 對 Claude 說：「執行 `tasks/2026-10-18-a4-poster-pack`」。

代理會依照 [`CLAUDE.md`](CLAUDE.md) 的流程工作，成品放在 `out/`，報告寫在 `REPORT.md`。

範例任務見 [`tasks/example-a4-batch/`](tasks/example-a4-batch/)。

---

## 常用做法

詳細的指令範例見 [`docs/recipes.md`](docs/recipes.md)，各工具的 CLI 說明見 [`docs/tools.md`](docs/tools.md)。

```sh
# 一張 PSD：執行命令後輸出
photocraft-cli run in/poster.psd --cmd <命令 ID> --params '<JSON>' --out out/poster.png

# 一整個資料夾：用一份 action 檔批次處理
photocraft-cli batch --actions work/a4.json --in in --out out --format jpg --quality 92

# 查看文件資訊（尺寸、色彩模式、圖層）
photocraft-cli info in/poster.psd

# 找命令與參數
photocraft-cli commands | grep -i size
```

批次轉 A4 有現成腳本：[`scripts/to-a4.sh`](scripts/to-a4.sh)。

---

## 目錄結構

```
.
├── README.md            本說明
├── CLAUDE.md            給 AI 代理的工作規則
├── setup/
│   ├── install.sh       安裝/更新 CLI（release 優先，失敗就從原始碼編譯）
│   ├── env.sh           source 後把 CLI 加進 PATH
│   └── status.sh        已安裝版本 vs 最新版本
├── scripts/             可重複使用的批次腳本（例如 to-a4.sh）
├── docs/
│   ├── tools.md         各 Craft CLI 的子命令與用法
│   └── recipes.md       常見任務的指令範例
└── tasks/
    ├── _template/       任務範本
    └── <任務>/          TASK.md、in/、out/、REPORT.md（work/ 不進版控）
```

---

## 授權與聲明

Crafting Apps 由 ArtCraft 團隊以 MIT 或 Apache-2.0 授權釋出，這個 repo 只放使用說明和腳本。Adobe、Photoshop、After Effects 等是 Adobe Inc. 的商標，ArtCraft 與 Adobe 沒有關係。
