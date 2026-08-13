# TurtleIMU（TTimu）

面向 iPhone / Android 的手机传感器实时监测应用，可同时读取：

- 加速度计（X / Y / Z，m/s² 含重力 + 合成值 + g）
- 陀螺仪（X / Y / Z，°/s）
- 磁力计（X / Y / Z，µT）
- 指南针航向（度 + 八方位）与 3D 姿态方块
- 温度（环境温度、体感温度、湿度；设备温度受浏览器限制）
- 速度（km/h、m/s）、经纬度（十进制度 + 度分秒）、高度（m / ft）、定位精度

核心是单文件 `www/index.html`，通过 GitHub Pages 部署后，手机浏览器（Safari / Chrome）直接可用，并保留 Capacitor 原生封装路线。

## 手机真机使用（推荐：GitHub Pages）

iOS Safari 只允许 HTTPS 页面读取定位和运动传感器，所以推荐部署到 GitHub Pages：

1. 在 github.com 用 `Kimoji798` 账号新建空仓库 `TTimu`（不要勾选 README）。
2. 双击 `部署到github.bat`，按提示输入仓库名 `TTimu`，回车。
3. 首次会弹出 GitHub 登录窗口，完成登录（需要 Clash 代理开着）。
4. 去仓库页 `Settings → Pages → Source` 选 `GitHub Actions` → `Save`（只需设置一次）。
5. 等 1–2 分钟，在手机打开 `https://kimoji798.github.io/TTimu/`，点「启动传感器」并允许「定位」「运动与方向」权限即可。

以后每次改完代码，再双击一次 `部署到github.bat` 就会自动更新。

## 本地电脑预览

双击 `启动服务器.bat`，窗口里会打印 `Phone URL` 和 `Demo URL`：

- `Phone URL`：手机连同一 WiFi 可打开，但 Safari 会因 HTTP 拦截定位/方向传感器。
- `Demo URL`（`?demo=1`）：不依赖传感器，用模拟数据演示界面。

关闭窗口 = 停止服务器。

## 传感器权限说明

- **iPhone（iOS 13+）**：必须用 HTTPS 打开；点「启动传感器」后会弹出「运动与方向」权限，定位会单独弹窗。
- **Android（Chrome）**：HTTPS 下定位和运动传感器通常直接可用；原始磁力计使用 `Magnetometer` Sensor API，若系统不支持则自动回退为指南针航向。
- 被拒绝后可在系统设置里重新允许，或点页面底部「重新授权」。

## 温度说明

浏览器出于安全限制无法读取设备/电池温度。本应用在取得定位后，会调用 Open-Meteo 免费气象接口显示「当前定位点的环境温度 / 体感温度 / 湿度」，作为温度读数；「设备温度」需通过 Capacitor 原生插件扩展。

## 项目结构

- `www/index.html` — 应用本体（CSS / JS 全部内联，单文件即可运行）
- `www/manifest.webmanifest` + `www/sw.js` — PWA 配置与离线缓存（可添加到主屏幕）
- `www/icon-1024.png` / `www/icon-180.png` / `www/favicon-32.png` — 各尺寸图标
- `server.js` + `启动服务器.bat` — 本地测试服务器
- `deploy.ps1` + `部署到github.bat` — 一键推送到 GitHub（dev + main）并触发 Pages
- `.github/workflows/pages.yml` — GitHub Pages 自动部署工作流（源目录 `www/`）
- `capacitor.config.json` / `package.json` — Capacitor 原生封装配置
- `make-icon.py` — 图标生成脚本

## 打包成原生 App

当前是 Capacitor 壳路线，网页版已可运行；需要原生打包时：

```bash
npm install
npx cap add ios
npx cap add android
npx cap sync
npx cap open ios        # 或 npx cap open android
```

注意两点：

- WKWebView 默认不触发网页的 `deviceorientation`，iOS 封装前需接入原生方向传感器插件或用 Swift 桥接 `CMMotionManager`，否则指南针/姿态不转。
- 在 `Info.plist` 补上：
  - `NSMotionUsageDescription`：用于读取运动与方向传感器
  - `NSLocationWhenInUseUsageDescription`：用于显示速度、经纬度、高度与温度
  - `CFBundleDisplayName`：TurtleIMU

## 已知限制

- iPhone Safari 不支持 `Magnetometer` 原始 XYZ，磁力计卡片会显示「不支持」并用指南针航向代替。
- 高度来自卫星定位（WGS84 椭球），精度有限；无定位时显示 `--`。
- 速度来自定位结果，静止或定位质量差时可能为 `--`。