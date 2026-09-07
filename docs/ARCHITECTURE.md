# 架构说明

## 1. 分层总览

组件库严格按「纯逻辑 ↔ UI」分离，依赖方向只能向下：

```
┌──────────────────────────────────────────────┐
│ render/MindMapView（ArkUI 组件，唯一 UI 层）    │
│  Canvas 画连线 + 定位卡片 + 手势识别            │
└───────┬───────────────────────────────────────┘
        │ 只读调用
┌───────▼───────────────────────────────────────┐
│ edit/EditController  编辑入口（选中态+增删改）  │
├───────────────────────────────────────────────┤
│ layout/LayoutEngine  坐标计算（纯逻辑）         │
│ gesture/ViewportController 视口状态机（纯逻辑） │
│ theme/ThemeManager   主题合并（纯逻辑）         │
│ export/JsonSerializer 序列化（纯逻辑）          │
│ export/ImageExporter  截图（薄设备层）           │
├───────────────────────────────────────────────┤
│ model/MindNode、MindTree  数据模型（纯逻辑）     │
└───────────────────────────────────────────────┘
```

- **model**：节点结构、父子关系、增删改、深度/遍历。`parent` 是运行期反向指针，不参与序列化。
- **layout**：输入 MindNode 树，输出 `LayoutNode[]`（坐标）+ `Edge[]`（连线锚点）+ 内容包围盒；不碰 UI。
  - V0.1 为「递归分层布局（简单但正确）」：x 由深度决定、叶子纵向占槽、父节点居中于首尾子节点，子树天然不重叠。
  - M2 升级紧凑 tidier 布局（子树轮廓合并），输入输出契约不变。
- **gesture**：ArkUI 只负责识别手势，缩放/平移/钳制/复位的确定性计算全部在 `ViewportController`，因此可离线单测。
- **edit**：持有唯一选中态，增删改全部委托 `MindTree`，并向 UI 发变更事件；UI 不直接改树。
- **export**：`JsonSerializer` 负责 JSON 往返与非法输入容错（纯逻辑）；`ImageExporter` 是组件截图/存相册的薄设备层（M4 完整落地）。
- **render**：`MindMapView` 组合上述能力；数据驱动，编辑后通过 `refreshTick` 自增重排。

## 2. 数据流

```
标准树 JSON
   │ JsonSerializer.deserialize（校验/容错）
   ▼
MindTree（单一数据源）
   │ LayoutEngine.layout
   ▼
LayoutResult（坐标 + 连线）──► MindMapView 渲染
   ▲                                │
   │ EditController 增删改           │ 手势 → ViewportController（缩放/平移）
   └────────────────────────────────┘
```

## 3. 与上层 AI 应用的边界

组件库**不内置任何 AI / 网络代码**：

- 上层 App（如 FocusTimer）组装 Prompt、调用 DeepSeek、对返回 JSON 做校验纠错；
- 大模型只需产出与 `SerializedNode` 同构的标准树节点 JSON；
- 组件 `JsonSerializer.deserialize` 后交给 `MindMapView` 渲染。

这样组件依赖轻量、职责单一、单测好维护，也更容易申请华为「优选三方库」。

## 4. 可测试性约定

- 纯逻辑类**不 import 任何系统 Kit / UI 组件**，全部放在 `src/test` 本地单测（Hypium，无需真机）；
- 必须上设备的（组件挂载、截图、相册）放 `src/ohosTest`；
- 测试夹具函数一律放模块顶层（ArkTS 禁止 `describe` 内嵌套声明函数）；
- 期望值独立推算，黄金坐标用例的期望值与实现分开手算。
