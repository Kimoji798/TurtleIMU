# TurtleIMU（TTimu）— AI 项目指引

> 面向 iPhone / Android 的手机传感器实时监测应用：加速度计、陀螺仪、磁力计、温度、速度、经纬度、高度。
> 本文件是项目级 AI 协作规范，优先级低于工作区根目录的 `AGENTS.md`。

## 技术栈与路线

- 采用 **Capacitor 壳路线**：核心为单文件前端 `www/index.html`，CSS / JS 全部内联，无构建步骤。
- 不安装 npm 依赖也能运行；`package.json` 仅用于后续 `npx cap` 原生封装。
- 线上地址：`https://kimoji798.github.io/TTimu/`（仓库 `Kimoji798/TTimu`）。

## 目录结构

- `www/index.html` — 单文件应用（内联 CSS、SVG 表盘、JS）
- `www/manifest.webmanifest` + `www/sw.js` — PWA
- `www/icon-1024.png` / `www/icon-180.png` / `www/favicon-32.png` — 图标
- `server.js` + `启动服务器.bat` — 本地静态服务器
- `deploy.ps1` + `部署到github.bat` — 一键推送 dev + main 并触发 Pages
- `.github/workflows/pages.yml` — Pages 部署（源目录 `www/`）
- `capacitor.config.json` / `package.json` — Capacitor 配置（appId `com.turtleworks.ttimu`）
- `make-icon.py` — 图标生成脚本

## 运行 / 验证

- 桌面预览（模拟数据）：`?demo=1`
- 本地静态服务器：`node server.js --smoke` 或双击 `启动服务器.bat`
- 语法检查：提取 `index.html` 内联 `<script>` 后 `node --check`；`server.js` 直接 `node --check server.js`

## 传感器实现约定

- **加速度计**：优先 `devicemotion.accelerationIncludingGravity`，回退 `devicemotion.acceleration`。
- **陀螺仪**：优先 `Gyroscope` Sensor API（rad/s → °/s），回退 `devicemotion.rotationRate`（β/γ/α 映射到 X/Y/Z 轴）。
- **磁力计**：`Magnetometer` Sensor API（µT）；不支持时卡片显示「不支持」并用指南针航向代替。
- **指南针**：`deviceorientationabsolute` / `deviceorientation`，iOS 取 `webkitCompassHeading`。
- **定位**：`Geolocation.watchPosition`，`enableHighAccuracy: true`。
- **温度**：Open-Meteo 当前天气接口（环境温度 / 体感 / 湿度），5 分钟节流；设备温度不可读。
- **权限流**：iOS 13+ 必须用户手势内调用 `DeviceOrientationEvent.requestPermission()` 与 `DeviceMotionEvent.requestPermission()`；启动后 5 秒无数据则状态标记为「无数据」。

## 关键约定

- 打开页面默认停在「启动传感器」按钮，点击后一次性完成全部授权并开始监听。
- 数值条为“零刻度居中”的双向条形：正数向右、负数向左。
- `copy` 按钮导出的 JSON 快照包含全部传感器 + 定位 + 温度 + 刷新率。
- 部署脚本使用代理 `127.0.0.1:7897`，默认仓库名 `TTimu`，GitHub 用户 `Kimoji798`。

## 已知坑

- WKWebView 默认不触发 `deviceorientation`，原生封装前需方向传感器插件 / Swift 桥接。
- iPhone Safari 不支持 `Magnetometer` 原始 XYZ。
- iOS 仅在 HTTPS 下允许定位与运动传感器，HTTP 本地测试会失败。

## 命名

- 中文名：TurtleIMU
- 英文名：TurtleIMU
- 工程目录：`TTimu`