/**
 * LayoutTypes —— 布局层类型定义（纯类型，无行为）。
 * 布局算法只吃标准 MindNode 树，输出带坐标的 LayoutNode / Edge，与渲染解耦：
 * 换一套绘制引擎（Canvas / Shape / 自定义自绘）不需要改算法。
 */

/** 布局可调参数；不传时使用 LayoutEngine.defaultConfig() */
export interface LayoutConfig {
  /** 节点卡片宽度（vp） */
  nodeWidth: number;
  /** 节点卡片高度（vp） */
  nodeHeight: number;
  /** 相邻层级之间的水平间距（vp） */
  hGap: number;
  /** 相邻兄弟子树之间的垂直间距（vp） */
  vGap: number;
  /** 整图左上角原点 x（vp） */
  originX: number;
  /** 整图左上角原点 y（vp） */
  originY: number;
}

/** 单个节点布局后的几何信息（左上角坐标 + 宽高 + 层级深度） */
export interface LayoutNode {
  id: string;
  /** 卡片左上角 x */
  x: number;
  /** 卡片左上角 y */
  y: number;
  width: number;
  height: number;
  /** 根为 0 */
  depth: number;
}

/** 父子连线（锚点已算好：父卡片右侧中点 → 子卡片左侧中点） */
export interface Edge {
  fromId: string;
  toId: string;
  fromX: number;
  fromY: number;
  toX: number;
  toY: number;
}

/** 一次完整布局的结果 */
export interface LayoutResult {
  nodes: LayoutNode[];
  edges: Edge[];
  /** 内容包围盒宽度（含原点偏移） */
  contentWidth: number;
  /** 内容包围盒高度（含原点偏移） */
  contentHeight: number;
}
