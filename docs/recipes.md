# 常見任務的指令範例

先執行 `source setup/env.sh`。標示 ✅ 的範例已在 photocraft-cli 0.10.0、pdfcraft-cli 0.9.0、effectcraft-cli 0.11.1 上實際測過。

---

## 1. 圖包批次轉成 A4（或其他紙張）✅

```sh
# 等比縮放，置中，白色留白，A4 直式 300 dpi，格式不變
scripts/to-a4.sh tasks/<任務>/in tasks/<任務>/out

# 依每張圖的方向自動選直式或橫式，裁切填滿整頁，輸出 PNG
scripts/to-a4.sh in out --orient auto --mode fill --format png

# 小圖不放大（避免模糊），淺灰底
scripts/to-a4.sh in out --no-enlarge --bg '#eeeeee'

# A3、150 dpi、輸出成 PDF
scripts/to-a4.sh in out --paper A3 --dpi 150 --format pdf

# 自訂尺寸（公釐）
scripts/to-a4.sh in out --paper 100x148mm
```

| 紙張 | 300 dpi 的像素 |
|---|---|
| A3 | 3508 × 4961 |
| A4 | 2480 × 3508 |
| A5 | 1748 × 2480 |
| Letter | 2550 × 3300 |

注意：

- WebP、GIF 等格式不記錄 dpi，像素尺寸仍然正確，但印刷時要另外指定 dpi。要給印刷廠時，建議輸出 PDF、TIFF 或 JPG。
- 輸出 PSD、TIFF 時保留圖層；輸出 JPG、PNG、PDF 時合併成單一圖層。

腳本對每張圖執行的命令如下（fit 模式）。如果所有圖片都用固定方向，也可以寫成 action 檔，交給 `batch` 一次處理：

```json
[
  ["file.automate.fitImage", {"width": 2480, "height": 3508, "dontEnlarge": false, "resample": "bicubic"}],
  ["image.canvasSize", {"width": 2480, "height": 3508, "anchor": "center", "extensionColor": "white"}],
  ["image.imageSize", {"resolution": 300, "resample": "none"}],
  ["layer.flattenImage", {}]
]
```

```sh
photocraft-cli batch --actions a4.json --in in --out out --format jpg --quality 92
```

## 2. 多張 A4 合併成一份 PDF ✅

```sh
scripts/to-a4.sh in work/pages --format pdf
pdfcraft-cli run doc_combine 'paths=["work/pages/01.pdf","work/pages/02.pdf"]' 'out="out/book.pdf"'
```

PDF 很多時，先用 shell 組出 `paths` 陣列，例如 `python3 -c 'import json,glob;print(json.dumps(sorted(glob.glob("work/pages/*.pdf"))))'`。`doc_combine` 也可以直接吃 PNG/JPG。

## 3. 檢查素材 ✅

```sh
photocraft-cli info in/poster.psd --compact      # 尺寸、模式、bit depth、圖層樹、缺字型警告
```

## 4. 單檔多步驟編修（PSD）

```sh
photocraft-cli run in/poster.psd \
  --cmd layer.newAdjustmentLayer.curves --params '{"points":[[0,0],[64,48],[192,212],[255,255]]}' \
  --cmd filter.sharpen.smartSharpen --params '{"amount":80}' \
  --out out/poster.psd
```

不確定命令 ID 或參數時，先查：

```sh
photocraft-cli commands --filter curves
photocraft-cli commands --json --filter image.canvasSize   # 含參數說明
```

## 5. 套用 Photoshop 的 Actions（.atn）

```sh
photocraft-cli batch --actions my-actions.atn --action "名稱" --in in --out out --format jpg
```

## 6. 轉檔 ✅

```sh
photocraft-cli convert in/a.psd out/a.png
photocraft-cli convert in/a.psd out/a.tif --tiff-layers     # 保留圖層的 TIFF
```

## 7. 動態圖像（EffectCraft）✅（算圖）

```sh
effectcraft-cli info --project main.ecproj
effectcraft-cli props Main 'Title' --flat --project main.ecproj      # 先查屬性路徑
effectcraft-cli set Main 'Title' <屬性路徑> '"秋季特賣"' --project main.ecproj --save
effectcraft-cli render-frame --project main.ecproj --comp Main --time 1 --out work/preview.png
effectcraft-cli render --project main.ecproj --comp Main --out out/main.mp4 --format h264
```

用同一個範本產出很多版本（批次換字）：`effectcraft-cli render --template T.ectemplate --values V.json --out …`

## 8. 照片批次顯影（LightCraft）

```sh
for f in in/*.{jpg,dng,cr3,nef,arw}; do
  [ -e "$f" ] || continue
  lightcraft-cli render "$f" -o "out/$(basename "${f%.*}").jpg" --set light.exposure=0.3 --size 3000 --quality 90
done
```
