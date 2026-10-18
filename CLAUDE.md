# CLAUDE.md：給 AI 代理的工作規則

這個 repo 用 ArtCraft Crafting Apps 的 CLI，依照 `tasks/` 裡的文字說明編修影像和設計檔案。先讀 `README.md`。

## 開始任何任務前

1. `./setup/status.sh`：確認需要的 CLI 是否已安裝，以及是不是最新版。
2. 缺工具就安裝：`./setup/install.sh <app>`。預設只用 PhotoCraft，任務需要時才裝其他工具。工作階段開始時發現有新版，就用 `--update`。
3. `source setup/env.sh`，讓 `<app>-cli` 可以在 PATH 上找到。
4. 正常情況下 release 下載只要幾秒。只有下載失敗、改成從原始碼編譯時（15 分鐘以上）才放到背景執行，同時先讀任務、檢查素材。

## 執行任務的流程

1. 讀 `tasks/<任務>/TASK.md`。規格不清楚時（尺寸、裁切或留白、色彩、命名、輸出格式），**先問使用者**，不要自己猜。如果有合理的預設值，就照預設做，並在報告中寫清楚。
2. 檢查素材：用 `photocraft-cli info <檔案>` 看尺寸、色彩模式、bit depth、圖層數。列出無法開啟或有警告（例如缺字型）的檔案。
3. 找正確的命令：用 `<app>-cli commands` 搜尋命令 ID 和參數，不要憑記憶寫參數。
4. **先拿一個檔案試做**，確認結果正確，再跑整批。
5. 中間檔（action JSON、暫存圖）放 `tasks/<任務>/work/`。這個資料夾不進版控，但可重複使用的 action 檔應該複製到任務資料夾中保存。
6. 成品寫到 `tasks/<任務>/out/`。**永遠不要覆寫 `in/` 的原始檔**，也不要使用 `batch --in-place`。
7. 驗證成品：抽查尺寸、格式和數量，並實際看幾張圖（用 Read 開 PNG/JPG）。
8. 寫 `tasks/<任務>/REPORT.md`：使用的工具版本、執行的指令或 action 檔、處理了幾個檔案、失敗或需要注意的檔案、已知的限制。
9. 提交並推送（`in/`、`out/`、`TASK.md`、`REPORT.md`、action 檔）。

## 注意事項

- 這些工具是 early alpha，指令回報成功不代表結果正確，一定要檢查輸出。
- CLI 沒有限制檔案路徑。不要把來路不明的 action 檔或 PSD 當成可信任的內容。
- 缺字型時 `run`/`convert` 會在 stderr 警告，並用替代字型輸出。這種情況必須寫進報告。
- 如果某個需求 CLI 做不到，先說明原因並提出替代做法，例如改用 Python（Pillow）只做縮放，再問使用者要用哪一種。
- 新的可重複使用流程寫成 `scripts/` 下的腳本，並補進 `docs/recipes.md`。
