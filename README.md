# MindMap-HarmonyOS

[![Repository-Check](https://github.com/yourname/MindMap-HarmonyOS/actions/workflows/ci.yml/badge.svg)](https://github.com/yourname/MindMap-HarmonyOS/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![ohpm](https://img.shields.io/badge/ohpm-%40yourname%2Fmindmap-success.svg)](https://ohpm.openharmony.cn/)

> 一行代码嵌入鸿蒙应用的**原生思维导图组件**：传入标准树节点 JSON，自动完成树形布局、渲染、缩放平移与节点编辑，并支持 JSON 序列化与图片导出。

## 亮点

- **纯原生、零 WebView**：基于 ArkUI 原生组件绘制，无 WebView 依赖，启动快、包体小、可离线。
- **自研紧凑树形布局算法**：内置后序轮廓（tidier）树形布局引擎，复杂度 O(n·深度)，兄弟子树按轮廓逐层避让、整树一次移位，不对称树也能紧凑不重叠，数据驱动、无需手摆坐标。
- **流畅手势**：双指缩放、单指平移、双击回到整树适配视图，大图浏览顺滑；初始进入自动整树适配居中（fit-to-screen），视口状态机为纯逻辑、可单测。
- **键盘流编辑（示例演示）**：EditDemo 支持回车加同级、Tab 加子级、输入框为空时 Delete 删除，连续录入不丢焦点；MindMapView 提供可选 `selectedId` 入参，选中节点以主题色（默认琥珀色）描边，不传则零影响。
- **图片导出**：组件截图走 `UIContext.ComponentSnapshot` 新 API（无弃用调用），`ImageExporter.saveToGallery` 经 photoAccessHelper 一键保存 PNG 到系统相册，含运行时权限申请与成功/失败/拒绝授权三态处理；HAR 本身不声明任何权限。
- **一行接入**：`ohpm install @yourname/mindmap`，三行代码渲染一张思维导图。
- **可定制**：主题配色、连线样式（曲线/折线）、节点样式、字号全部可配置。
- **工程质量**：74 个本地单元测试覆盖数据模型、布局算法（含独立手算黄金坐标与随机树不变量审计）、视口状态机、整树适配纯函数、序列化、编辑控制与主题（随里程碑持续增加）。

## 快速上手

### 1. 安装

```bash
ohpm install @yourname/mindmap
```

### 2. 三行代码渲染思维导图

```typescript
import { MindTree, MindNode, MindMapView } from '@yourname/mindmap';

// 1. 准备标准树节点数据（也可由后端 / 大模型生成同构 JSON 后反序列化得到）
const tree: MindTree = new MindTree('中心主题');
tree.addChildTo(tree.root.id, new MindNode('n1', '分支一'));

// 2. 在 build() 中挂载组件；编辑后把 refreshTick 自增即可触发重新布局
@Builder
mindMap() {
  MindMapView({ root: this.tree.root, refreshTick: this.tick })
}
```

### 3. 标准树节点 JSON 契约

组件只认数据、不内置任何 AI / 网络依赖：

```json
{
  "id": "root",
  "text": "中心主题",
  "collapsed": false,
  "color": "",
  "children": [
    { "id": "n1", "text": "分支一", "collapsed": false, "color": "", "children": [] }
  ]
}
```

## 目录结构

```
MindMap-HarmonyOS/
├── entry/                 # Demo 应用（基础/手势/编辑/导出四个示例页）
│   └── src/main/ets/
│       ├── pages/         # Index / BasicDemo / GestureDemo / EditDemo / ExportDemo
│       └── common/        # 示例数据
├── library/               # HAR 组件库（发布到 ohpm 的包）
│   ├── Index.ets          # 对外统一导出入口
│   └── src/main/ets/
│       ├── model/         # MindNode / MindTree 数据模型（纯逻辑）
│       ├── layout/        # LayoutEngine 树形布局算法（纯逻辑，核心卖点）
│       ├── render/        # MindMapView 渲染组件（ArkUI）
│       ├── gesture/       # ViewportController 视口状态机（纯逻辑）
│       ├── edit/          # EditController 编辑能力（纯逻辑）
│       ├── export/        # JsonSerializer 序列化 + ImageExporter 图片导出
│       └── theme/         # 主题模型与默认主题（纯逻辑）
├── docs/                  # 架构 / API / 里程碑文档
├── AppScope/              # Demo 应用级配置
└── .github/workflows/     # 云端只做仓库规范校验（原因见下文「构建与测试」）
```

## 分层架构与设计原则

- **UI 与纯逻辑分离**：model / layout / gesture / edit / export(序列化) / theme 全部是不依赖 UI 的纯逻辑类，可离线单测；render 只负责把结果画出来。
- **组件库不内置 AI 依赖**：安装 `@yourname/mindmap` 不需要任何 API Key。AI 生成脑图的逻辑放在上层 App（如 FocusTimer 组装 Prompt、调用 DeepSeek、校验 JSON），组件只接收标准树节点数据。
- **单一数据源**：编辑只走 `EditController` 一个入口，渲染层只读不改树。

详见 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) 与 [docs/API.md](docs/API.md)。

## AI 协作开发策略

本项目采用双模型互补分工：**DeepSeek 负责树算法、结构化 JSON、工具函数、文本转脑图数据；豆包 Seed 负责复杂 ArkTS 自定义 UI 渲染与依赖现有接口的业务接线**。任务路由表、交接流水线与质量门见 [docs/AI_COLLAB_STRATEGY.md](docs/AI_COLLAB_STRATEGY.md)。

## 构建与测试（重要）

HarmonyOS API 24 SDK / hvigor 需登录华为开发者中心下载，**GitHub Actions 云端无法获取**，因此：

- **云端 CI**：只做仓库规范门禁（LICENSE / README / 六层目录 / 测试目录存在性），保证徽章稳定绿；
- **构建与单元测试**：统一在本地 **DevEco Studio 6.1+（API 24）** 执行：
  - 本地单测：对 `library/src/test` 运行单元测试（纯逻辑、无需真机）；
  - 设备测试：`library/src/ohosTest`（渲染挂载、截图核验）；
  - 构建：Build > Build Hap(s)/APP(s)。

## 发布到 ohpm

1. 在 [ohpm 中心仓](https://ohpm.openharmony.cn/) 注册账号并完成实名认证；
2. 把 `library/oh-package.json5` 中的 `@yourname/mindmap` 改为真实包名，补全 author / version / keywords；
3. 在 `library/` 目录执行 `ohpm publish`，通过自动化扫描与人工审核；
4. 验证 `ohpm install @你的包名/mindmap` 可正常安装。

## 落地案例

> 本组件已在个人项目 **FocusTimer**（HarmonyOS 专注计时 + DeepSeek AI 应用）中实际落地：FocusTimer 基于用户计时/笔记数据调用 DeepSeek 生成思维导图结构化 JSON，交由本组件在 App 内直接渲染效率复盘脑图。

## 路线图

见 [docs/ROADMAP.md](docs/ROADMAP.md)（M1 工程+模型 → M6 上架运营）。

## 发布前待办（脚手架占位项）

- [ ] 全局替换 `yourname`：`library/oh-package.json5`、`entry/oh-package.json5`、entry 内 import、AppScope `bundleName`、本文件徽章链接
- [ ] 补 Demo 运行截图到 `screenshots/` 并替换上方占位
- [x] M2 算法侧：后序轮廓紧凑 tidier 布局已落地（黄金坐标 + 1000 随机树零违例）
- [ ] M2 渲染侧：MindMapView 设备目视回归与 Demo 截图
- [x] M4：ImageExporter 保存相册（photoAccessHelper + 权限声明，截图迁移 UIContext.ComponentSnapshot 新 API）

## License

[Apache-2.0](LICENSE)
