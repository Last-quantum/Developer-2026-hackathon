# Career Plan AI

一个基于 Flutter 的职业学习计划生成 App：

- 输入目标岗位
- 由 AI 反问关键问题
- 生成 8 周学习框架
- 下钻到每周 7 天任务
- 生成学习文档并在“日程/文件”中查看

## 本地运行

```bash
flutter pub get
flutter run
```

## 后端（Vercel Serverless + TypeScript）

项目已新增 `backend/`，用于代理 Coze 请求，解决 Web 端跨域并隐藏 PAT。

### 目录

```text
backend/
	api/
		coze-chat.ts        # Serverless Function: 代理 Coze
	.env.example
	package.json
	tsconfig.json
	vercel.json
```

### 本地启动后端（推荐，先不用部署）

```bash
cd backend
npm install
```

复制环境文件：

- PowerShell：

```powershell
Copy-Item .env.example .env
```

- macOS/Linux：

```bash
cp .env.example .env
```

在 `backend/.env` 中填写：

- `COZE_PAT`
- `COZE_BOT_ID`
- `ALLOWED_ORIGIN`（本地可先写 `*` 或 Flutter Web 的本地地址）

然后启动：

```bash
npm run dev:local
```

默认本地地址通常是 `http://localhost:3000`。

> `dev:local` 不依赖 Vercel 登录，适合团队本地联调。

### 可选：使用 Vercel 本地模拟

```bash
npm run dev
```

该命令会走 `vercel dev`，首次通常需要 `vercel login`。

### Flutter 侧联调（重要）

Flutter 现在通过编译参数读取后端地址：`API_BASE_URL`。

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

Windows 桌面同理：

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:3000
```

## 联通自检（30 秒）

后端启动后，先直接验证代理接口：

```powershell
Invoke-WebRequest -Method Post -Uri http://localhost:3000/api/coze-chat -ContentType 'application/json' -Body '{"query":"请返回一句测试成功"}'
```

如果返回 JSON 且包含 `content` 字段，说明“前端 -> 本地后端 -> Coze”链路已打通。

## 当前代码结构（重构后）

```text
lib/
	main.dart                         # 仅应用入口
	app/
		app.dart                        # MyApp、主题、Provider 注入
	features/
		input/presentation/
			input_page.dart               # 岗位输入 + AI 问题问卷
		main_shell/presentation/
			main_app_page.dart            # 底部导航容器
		plan/
			application/
				app_state.dart              # 主要状态管理 + Coze API 调用
			domain/models/
				study_week.dart
				study_day.dart
			presentation/
				chat_plan_view.dart         # 周/天计划视图
		calendar/presentation/
			calendar_view.dart            # 日程视图
		files/presentation/
			files_view.dart               # 文档视图
```

## 本次重构做了什么

- 将原先集中在 `main.dart` 的模型、状态管理、页面全部拆分
- 保持现有功能与交互不变，降低多人协作时的合并冲突
- 让页面层（presentation）与业务逻辑（application）职责更清晰

## 协作建议

- 页面改动优先在 `features/*/presentation` 下进行
- 业务状态与请求逻辑集中在 `features/plan/application/app_state.dart`
- 新增功能优先按 feature 分目录，不再回写到 `main.dart`

## 安全提醒（建议尽快做）

PAT 已迁移到后端环境变量；前端不再直接持有 Coze 凭据。后续可继续接入 MongoDB Atlas（如记录请求日志、清洗后落库）再由 Vercel Function 统一处理。
