/**
 * mindmap-harmony —— HarmonyOS NEXT 原生思维导图组件库（HAR）统一导出入口。
 *
 * 组件库不内置任何 AI / 网络依赖，只接收标准树节点数据，
 * 负责布局、渲染、手势、编辑、序列化与导出。
 *
 * 公共 API 分层导出，使用方只从本入口 import：
 *   import { MindMapView, MindTree, MindNode, JsonSerializer, EditController } from 'mindmap-harmony';
 */

// 数据模型层
export { MindNode } from './src/main/ets/model/MindNode';
export { MindTree } from './src/main/ets/model/MindTree';

// 布局算法层
export { LayoutEngine } from './src/main/ets/layout/LayoutEngine';
export { LayoutConfig, LayoutNode, Edge, LayoutResult } from './src/main/ets/layout/LayoutTypes';

// 主题层
export { ThemeManager, MindMapTheme, MindMapLineType } from './src/main/ets/theme/MindMapTheme';

// 视口 / 手势状态机层
export { ViewportController } from './src/main/ets/gesture/ViewportController';

// 编辑层
export { EditController, MindMapChangeType, MindMapChangeEvent, MindMapChangeListener } from './src/main/ets/edit/EditController';

// 序列化 / 导出层
export { JsonSerializer, MindMapSerializeError, SerializeErrorCode, SerializedNode, SerializedDocument } from './src/main/ets/export/JsonSerializer';
export { ImageExporter, ImageExportCode, ImageExportResult } from './src/main/ets/export/ImageExporter';

// 渲染组件层
export { MindMapView } from './src/main/ets/render/MindMapView';
