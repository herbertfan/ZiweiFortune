# 紫微斗數 App 開發規範

## Git 版本控制規範

### 分支策略
- 主線：`main`（穩定版）、`develop`（開發版）
- 功能分支：`feature/功能名稱`
- 修復分支：`fix/問題描述`
- 雜項分支：`chore/調整內容`

### Commit 訊息格式（Conventional Commits）
格式：`<type>: <簡短描述>`

類型：
- `feat`: 新功能
- `fix`: 修正 bug
- `chore`: 設定或工具調整
- `docs`: 文件更新
- `refactor`: 重構（不影響功能）
- `test`: 測試相關

### 開發守則
1. 每次開始新任務前，確認目前 git 狀態（`git status`）
2. 重大修改前，先建立新分支，不在 `main` 直接編輯
3. 每個功能完成後立即 commit，避免大型 commit
4. 修改前若無分支，請提醒我先 commit 或建立分支再繼續

### 強制前置檢查（每次修改任務前必須執行）
每次使用者要求修改任何程式碼或檔案之前，必須依序執行以下動作，**不得跳過**：

1. 執行 `git status` 確認目前狀態
2. 執行 `git add .` 和 `git commit`，commit 訊息格式為：
   ```
   chore: snapshot before [根據任務自動填寫描述]
   ```
3. 執行 `git push` 推送到 GitHub 遠端目前分支
4. 確認 push 成功後，才開始執行使用者的修改任務

## Xcode 測試規範（每次修改程式碼後必須執行）

### 專案資訊
- 專案：ziwei-fortune.xcodeproj
- Scheme：ziwei-fortune
- 測試 Target：ziwei-fortuneTests

### 強制規則
每次修改任何 Swift 程式碼後，必須依序執行：

1. 用 XcodeBuildMCP 工具執行建置與測試：
```bash
xcodebuild test \
  -project ziwei-fortune.xcodeproj \
  -scheme ziwei-fortune \
  -destination 'platform=macOS' \
  -resultBundlePath TestResults.xcresult 2>&1 | xcpretty --color
```

2. 若出現 BUILD FAILED 或 TEST FAILED → 停止當前任務，先修復
3. 全部 PASSED 後，才可執行 git commit
4. 每新增一個功能，必須在 ziwei-fortuneTests/ 目錄下新增對應的 XCTest 測試案例

### TDD 開發流程
1. 先寫 XCTest 測試（RED — 預期失敗）
2. 再寫實作讓測試通過（GREEN）
3. 重構程式碼，確認測試仍然通過（REFACTOR）
