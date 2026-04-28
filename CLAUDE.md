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
