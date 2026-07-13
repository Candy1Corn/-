# 🐾 小圓桌面寵物

透明無框、永遠浮在最上層的桌寵！不會搶走焦點，滑鼠可以穿透空白區域。

## 安裝與執行

### 需要先安裝
- [Node.js](https://nodejs.org) v18 以上

### 步驟

```bash
cd xiaoyuan-desktop-pet
npm install
npm start
```

> ⚡ 已內含 `.npmrc` 使用快速鏡像站，下載 Electron 不會中斷

## 操作說明

| 操作 | 效果 |
|------|------|
| 左鍵點擊小圓 | 逗她玩、讓她跳起來 |
| 右鍵點擊 | 選單（跳躍 / 打招呼 / 休息 / 結束）|
| 拖曳 | 把她拖到螢幕任意位置 |
| 放著不管 | 她會自己在螢幕上走來走去、偶爾揮手 |

## 自訂調整

**`main.js`**
- `SCALE = 4` → 顯示大小（3=小，5=大）
- `alwaysOnTop: true` → 改 false 不置頂

**`index.html`**
- `WALK_SPEED = 1.8` → 走路速度
- `ANIM_FPS = 8` → 動畫幀率
- `pickBehaviour()` 裡的機率 → 調整行為頻率

## 檔案結構

```
xiaoyuan-desktop-pet/
├── main.js         ← Electron 主程序（透明視窗）
├── preload.js      ← 安全的 IPC 橋接
├── index.html      ← 小圓的動畫邏輯與渲染
├── xiaoyuan.png    ← 手工繪製的像素 Sprite Sheet
│                      128×192px，4×6 格，每格 32×32
├── .npmrc          ← 使用快速鏡像，避免下載失敗
└── package.json
```

## Sprite Sheet 說明

```
Row 0: idle  (待機)
Row 1: walk_a (走路 A)
Row 2: walk_b (走路 B)
Row 3: jump  (跳躍)
Row 4: wave  (揮手)
Row 5: sleep (睡覺)
```
