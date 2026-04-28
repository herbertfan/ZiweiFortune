# Apple Liquid Glass 設計指導文件
## iOS 26 / macOS Tahoe — Claude Code App 設計規範

> **適用範圍：** iOS 26、iPadOS 26、macOS 26 Tahoe、watchOS 26  
> **核心設計語言：** Liquid Glass（液態玻璃）  
> **資料來源：** Apple WWDC 2025 Session 219、323、310 及 Apple 官方文件

---

## 一、設計哲學總覽

Liquid Glass 是 Apple 自 iOS 7 以來最大規模的視覺設計更新，源自 visionOS 的空間設計語言，延伸至所有 Apple 平台。

### 核心精神
- **真實光學模擬**：不再是毛玻璃散射光，而是「Lensing」——動態彎曲、聚焦光線
- **三維層次空間**：介面成為三維空間，元件「浮」於內容之上
- **內容優先**：玻璃材質讓內容穿透，控制元件退為輔助角色
- **跨平台統一**：iPhone、iPad、Mac、Apple Watch 共享同一設計語言
- **動態自適應**：即時對環境光、深色/淺色模式、背景內容做出反應

---

## 二、Liquid Glass 材質特性

### 視覺特徵
| 特性 | 說明 |
|------|------|
| 透明折射 | 元件像真實玻璃般折射背後內容 |
| 鏡面高光 | 依光源方向動態產生鏡面反射（Specular Highlight） |
| 環境反射 | 側邊欄、Dock 會反射鄰近的壁紙或彩色內容 |
| 色彩採樣 | 玻璃顏色由周圍內容動態決定，非固定色 |
| 深度感 | 多層玻璃堆疊製造視覺深度，非平面設計 |

### 兩種玻璃變體

| 變體 | 用途 | 何時使用 |
|------|------|----------|
| `.regular`（預設） | 大多數介面元素 | 工具列、標籤列、浮動按鈕 |
| `.clear` | 媒體豐富場景 | 僅在照片/影片上方且內容不會被暗化時使用 |

> ⚠️ **嚴禁混用兩種變體**：同一群組內的玻璃元素必須使用相同變體。

---

## 三、黃金法則：玻璃僅用於導覽層

```
App 層次結構
┌─────────────────────────────┐
│  導覽層（Liquid Glass）      │  ← 玻璃元件放這裡
│  ─ 工具列 / 標籤列 / 側邊欄  │
│  ─ 浮動按鈕 / Sheet / Popover│
├─────────────────────────────┤
│  內容層（無玻璃）            │  ← 列表、卡片、文字、圖片
│  ─ List / ScrollView        │
│  ─ 卡片 / 表格               │
└─────────────────────────────┘
```

### ✅ 玻璃應用於
- NavigationBar、TabBar、Toolbar
- 浮動動作按鈕（FAB）
- Sheet、Popover、Menu、Alert
- Control Center 元件
- 搜尋列

### ❌ 玻璃絕對不用於
- List / 卡片 / 表格（內容層）
- 全螢幕背景
- 可滾動內容內部的元素
- 純裝飾性元素

---

## 四、核心 API 使用規範（SwiftUI）

### 4.1 基本 glassEffect 用法

```swift
// 基本玻璃效果
Button("動作") { }
    .glassEffect()

// 指定形狀
Button("圓形") { }
    .glassEffect(.regular, in: .circle)

Button("膠囊形") { }
    .glassEffect(.regular, in: .capsule)

// iOS 互動回饋（觸控時縮放/彈跳/光暈）
Button("互動") { }
    .glassEffect(.regular.interactive())
```

### 4.2 GlassEffectContainer（多元素必用）

> **核心規則**：多個玻璃元素必須包在 `GlassEffectContainer` 內，否則各自獨立採樣，外觀不一致。

```swift
// ✅ 正確：使用容器
GlassEffectContainer {
    HStack(spacing: 16) {
        Button("編輯") { }.glassEffect()
        Button("分享") { }.glassEffect()
        Button("刪除") { }.glassEffect()
    }
}

// ❌ 錯誤：沒有容器
HStack {
    Button("編輯") { }.glassEffect()
    Button("分享") { }.glassEffect()  // 各自獨立採樣，不一致
}
```

**spacing 參數**：距離在 spacing 值內的元素會自動融合成一塊玻璃。

### 4.3 玻璃形變（Morphing）

```swift
struct ExpandableToolbar: View {
    @State private var isExpanded = false
    @Namespace private var ns

    var body: some View {
        GlassEffectContainer(spacing: 20) {
            HStack(spacing: 12) {
                if isExpanded {
                    Button("相機", systemImage: "camera") { }
                        .glassEffect(.regular.interactive())
                        .glassEffectID("camera", in: ns)

                    Button("照片", systemImage: "photo") { }
                        .glassEffect(.regular.interactive())
                        .glassEffectID("photos", in: ns)
                }

                Button {
                    withAnimation(.bouncy) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .glassEffectID("toggle", in: ns)
            }
        }
    }
}
```

**Morphing 三要素**：
1. 元素在同一個 `GlassEffectContainer` 內
2. 每個元素都有 `glassEffectID` + 共用 namespace
3. 狀態變更時套用動畫

### 4.4 按鈕樣式

| 樣式 | 外觀 | 使用場景 |
|------|------|----------|
| `.glass` | 半透明 | 次要動作 |
| `.glassProminent` | 不透明（強調） | 主要動作（唯一） |

```swift
HStack {
    Button("取消") { }
        .buttonStyle(.glass)

    Button("確認") { }
        .buttonStyle(.glassProminent)
        .tint(.blue)  // 僅主要按鈕加色調
}
```

### 4.5 Tinting（色調）規則

> **原則**：色調只用於強調主要動作，過度使用反而失去強調效果。

```swift
// ✅ 只有主要動作上色
Button("儲存") { }
    .buttonStyle(.glassProminent)
    .tint(.blue)

// ❌ 每個按鈕都上不同顏色 = 視覺噪音
Button("A") { }.glassEffect(.regular.tint(.blue))
Button("B") { }.glassEffect(.regular.tint(.green))  // 禁止
```

---

## 五、AppKit / macOS 規範

### NSButton 玻璃樣式
```swift
let button = NSButton()
button.bezelStyle = .glass
button.bezelColor = .systemBlue  // 僅主要動作
```

### macOS 自動化元素
重新編譯後自動獲得 Liquid Glass：
- Toolbar、Sidebar、Menu bar、Dock
- Window controls、NSPopover、Sheets

### Sidebar 環境反射
macOS / iPadOS 側邊欄會自動反射鄰近彩色內容，開發者無需額外處理。

### Toolbar 群組
AppKit 自動將多個 toolbar 按鈕合併在一塊玻璃上。使用 `NSToolbarItemGroup` 或 spacer 自訂群組邊界。

---

## 六、導覽列與標籤列行為規範

### Tab Bar 動態收縮（iOS 26 新行為）
- 向下滾動時：Tab Bar **縮小**，讓內容獲得更多空間
- 向上滾動時：Tab Bar **流暢展開**恢復完整大小
- 設計要求：導覽項目即使縮小也要清晰可識別，建議使用 SF Symbols

### Navigation Bar
- 滾動時玻璃導覽列自動過渡為緊湊型
- Hero 圖片可流暢收縮進導覽列（見 AllTrails 範例）

### Sidebar（iPadOS / macOS）
- 側邊欄折射背後內容同時反射壁紙
- 確保側邊欄文字/圖示在各種背景下保持可讀性

---

## 七、動畫與互動規範

### 動畫風格
- 使用 `.bouncy`（彈性）動畫搭配玻璃形變
- 玻璃元素出現/消失：**不要硬切**，使用淡入淡出或縮放過渡
- 觸控反饋：`.interactive()` 修飾符自動處理縮放、彈跳、觸控光暈

### 玻璃形變動畫原則
```swift
// 推薦：使用 .bouncy 讓玻璃形變有真實物理感
withAnimation(.bouncy) {
    isExpanded.toggle()
}

// 次選：spring 動畫
withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
    showPanel.toggle()
}
```

### 通知與 Sheet 動畫
- 通知從螢幕頂部優雅滑入
- Lock screen 通知顯示於底部
- 時鐘根據通知數量動態調整大小

---

## 八、嚴禁規則（反模式）

### 1. 禁止玻璃疊玻璃
```swift
// ❌ 絕對禁止
VStack {
    HeaderView().glassEffect()
    ContentView().glassEffect()  // 玻璃無法正確採樣另一層玻璃
}
```

### 2. 禁止在內容層使用玻璃
```swift
// ❌ 禁止
List {
    ForEach(items) { item in
        Text(item.name).glassEffect()  // 內容層不加玻璃
    }
}
```

### 3. 禁止混用 Regular 和 Clear 變體
```swift
// ❌ 禁止
HStack {
    Button("A") { }.glassEffect(.regular)
    Button("B") { }.glassEffect(.clear)  // 不同變體不可共存
}
```

### 4. 禁止為所有元素上色
```swift
// ❌ 禁止 - 失去強調意義
Button("A") { }.glassEffect(.regular.tint(.blue))
Button("B") { }.glassEffect(.regular.tint(.green))
Button("C") { }.glassEffect(.regular.tint(.red))
```

### 5. 禁止多玻璃元素不用容器
```swift
// ❌ 禁止
HStack {
    Button("A") { }.glassEffect()
    Button("B") { }.glassEffect()
}

// ✅ 必須包裝
GlassEffectContainer {
    HStack {
        Button("A") { }.glassEffect()
        Button("B") { }.glassEffect()
    }
}
```

---

## 九、無障礙設計（系統自動處理）

以下設定開啟時，Liquid Glass 自動調整，開發者**無需額外程式碼**：

| 系統設定 | Liquid Glass 效果 |
|----------|------------------|
| 降低透明度（Reduce Transparency） | 玻璃變為磨砂（Frostier） |
| 增強對比度（Increase Contrast） | 黑/白不透明 + 邊框 |
| 降低動態效果（Reduce Motion） | 停用彈性動畫 |

### 對比度自動保護
系統偵測到文字在複雜背景上可讀性不足時，**自動提高不透明度**保護可讀性，無需手動介入。

---

## 十、圖示（App Icon）設計規範

### iOS 26 圖示層次
- App 圖示由**多層 Liquid Glass** 組成
- 支援三種外觀模式：
  1. 標準（原始彩色圖示）
  2. 深色（暗色版本）
  3. 色調（Tinted）——去色 + 使用者選擇色彩
- 建議為每種模式提供專屬設計，而非僅靠系統自動轉換

### macOS Tahoe Dock 圖示
- 圖示和 Widget 由多層 Liquid Glass 打造
- 使用者可選擇：無色透明、色調著色、深色版本

---

## 十一、Zero-Code 免費升級清單

只需用 **Xcode 26** 重新編譯，以下元素自動套用 Liquid Glass：

**iOS 26：**
- NavigationBar、TabBar、Toolbar
- Sheet、Popover、Menu、Alert
- Search Bar、Control Center
- Toggle、Slider、Picker（互動時）

**macOS Tahoe：**
- Toolbar、Sidebar、Menu bar、Dock
- Window controls、NSPopover、Sheets

---

## 十二、設計決策速查表

```
需要放玻璃嗎？

元素是否浮在內容上方？
├── 是 → 它是導覽/控制元件嗎？
│         ├── 是 → ✅ 使用 glassEffect()
│         └── 否 → ❌ 不使用玻璃
└── 否 → ❌ 不使用玻璃（內容層）

有多個玻璃元素嗎？
└── 是 → ✅ 必須包進 GlassEffectContainer

需要強調主要動作嗎？
├── 是（唯一主要動作） → ✅ .buttonStyle(.glassProminent) + .tint(color)
└── 否（次要動作） → .buttonStyle(.glass) 不加色調

在照片/影片上方？
├── 是，且內容不被暗化 → 可考慮 .glassEffect(.clear)
└── 否 → 使用預設 .glassEffect(.regular)
```

---

## 十三、參考資源

| 資源 | 說明 |
|------|------|
| [WWDC25 Session 219: Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/) | Liquid Glass 設計原理 |
| [WWDC25 Session 323: Build a SwiftUI app with the new design](https://developer.apple.com/videos/wwdc2025/323/) | SwiftUI 實作指南 |
| [WWDC25 Session 310: Build an AppKit app with the new design](https://developer.apple.com/videos/wwdc2025/310/) | AppKit / macOS 實作指南 |
| [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) | 官方 HIG 完整規範 |
| [Apple Liquid Glass Overview](https://developer.apple.com/documentation/TechnologyOverviews/liquid-glass) | 官方技術文件 |
| [Apple New Design Gallery](https://developer.apple.com/design/new-design-gallery-2026/) | 真實 App 範例展示 |

---

*最後更新：2026 年 4 月 | 適用版本：iOS 26、iPadOS 26、macOS 26 Tahoe、watchOS 26*
