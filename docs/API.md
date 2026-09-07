# API 文档（V0.1 骨架版）

所有公共 API 从包入口统一导入：

```typescript
import {
  MindNode, MindTree, LayoutEngine, ViewportController,
  EditController, JsonSerializer, ThemeManager, MindMapView
} from '@yourname/mindmap';
```

## 1. 数据模型

### MindNode

| 成员 | 说明 |
|---|---|
| `id: string` | 全树唯一 id |
| `text: string` | 节点文本 |
| `children: MindNode[]` | 有序子节点 |
| `parent: MindNode \| null` | 运行期父指针（不序列化） |
| `collapsed: boolean` | 是否折叠子树（V0.2 出动画） |
| `color: string` | 自定义配色，空串走主题 |
| `addChild / insertChildAt / removeChild` | 父子关系维护，自动维护反向指针、拒绝成环 |
| `depth() / isLeaf() / isRoot() / childCount()` | 结构查询 |

### MindTree

| 成员 | 说明 |
|---|---|
| `findById(id)` / `contains(id)` | 查找 |
| `depthOf(id)` / `pathToRoot(id)` / `pathIdsToRoot(id)` | 深度与父路径 |
| `preorder()` / `breadthFirst()` / `leaves()` / `count()` | 遍历与统计 |
| `createNode(text)` | 生成带自动 id 的节点 |
| `addChildTo / appendNewChild / insertSiblingAfter` | 新增 |
| `remove(id)` | 删除整棵子树（根受保护） |
| `updateText / setCollapsed` | 修改 |

## 2. 布局

```typescript
const engine = new LayoutEngine();
const result = engine.layout(tree.root, LayoutEngine.defaultConfig());
// result.nodes: LayoutNode[]（id/x/y/width/height/depth）
// result.edges: Edge[]（fromId/toId/锚点坐标）
// result.contentWidth / contentHeight
```

`LayoutConfig`：`nodeWidth 160`、`nodeHeight 44`、`hGap 48`、`vGap 16`、`originX/Y 24`（vp）。

## 3. 渲染组件

```typescript
MindMapView({
  root: this.tree.root,        // MindNode 树根（只读）
  refreshTick: this.tick,      // 编辑后自增触发重排
  theme: customTheme,          // 可选，默认 ThemeManager.defaultTheme()
  layoutConfig: null,          // 可选自定义布局参数
  onNodeSelect: (id: string) => {}
})
```

内置手势：双指缩放（0.5x~3x）、单指平移（自动钳制不露白边）、双击复位。
需要导出截图时给组件挂 `.id('mindmap_canvas')`。

## 4. 编辑

```typescript
const editor = new EditController(tree);
editor.select(id);
editor.addChildToSelected('子节点');
editor.addSiblingAfterSelected('同级节点');
editor.updateSelectedText('新文本');
editor.removeSelected();       // 根受保护，删除后选中态回落到父节点
editor.toggleCollapseSelected();
editor.addListener({ onChange: (e) => {} });
```

## 5. 序列化

```typescript
const text = JsonSerializer.serializeTree(tree, '2026-09-07'); // 带信封（format/version/root）
const restored = JsonSerializer.deserialize(text);             // 也接受裸节点 JSON
```

非法输入抛 `MindMapSerializeError`，错误码：`EMPTY_INPUT / INVALID_JSON / MISSING_FIELD / WRONG_TYPE`。

## 6. 主题

```typescript
const theme = ThemeManager.defaultTheme();
theme.rootFillColor = '#FF0000';
const merged = ThemeManager.merge(ThemeManager.defaultTheme(), theme);
```

可配置：背景/根节点/普通节点/选中色、文字与连线色、线宽、圆角、字号、连线类型（`curve | polyline`）。

## 7. 图片导出（M4 补全）

```typescript
const pixelMap = await ImageExporter.capture('mindmap_canvas');
// saveToGallery 将在 M4 通过 photoAccessHelper 实现（含 WRITE_IMAGEVIDEO 权限与容错）
```
