import { MindNode } from '../model/MindNode';
import { LayoutConfig, LayoutNode, Edge, LayoutResult } from './LayoutTypes';

/**
 * LayoutEngine —— 自研树形布局引擎（纯逻辑，不依赖 UI，核心卖点，全部坐标可单测）。
 *
 * V0.1 先交付文档约定的保底算法「递归分层布局（简单但正确）」：
 * - 水平向右生长：x 只由层级深度决定，保证同层节点纵向对齐；
 * - 后序递归：先排子树，父节点垂直居中于「第一个子节点 ~ 最后一个子节点」；
 * - 叶子按顺序纵向占槽，兄弟子树之间留 vGap，从机制上保证子树不重叠。
 *
 * M2 里程碑在此基础上升级更紧凑的 tidier 树布局（子树轮廓合并、子树位移），
 * 输入输出契约不变，渲染层与测试用例无需改动。
 */
export class LayoutEngine {
  private cfg: LayoutConfig = LayoutEngine.defaultConfig();
  private nodeMap: Map<string, LayoutNode> = new Map<string, LayoutNode>();
  private edgesOut: Edge[] = [];
  private cursorY: number = 0;

  /** 默认布局参数（vp），调用方可只覆盖其中一部分前先取这份基线 */
  static defaultConfig(): LayoutConfig {
    const config: LayoutConfig = {
      nodeWidth: 160,
      nodeHeight: 44,
      hGap: 48,
      vGap: 16,
      originX: 24,
      originY: 24
    };
    return config;
  }

  /**
   * 对一棵 MindNode 树执行布局，返回每个节点的左上角坐标、父子连线锚点与内容包围盒。
   * 纯函数语义：相同输入必得相同输出，不修改入参树。
   */
  layout(root: MindNode, config?: LayoutConfig): LayoutResult {
    this.cfg = config === undefined ? LayoutEngine.defaultConfig() : config;
    this.nodeMap = new Map<string, LayoutNode>();
    this.edgesOut = [];
    this.cursorY = this.cfg.originY;

    this.placeNode(root, 0);

    // 按树的前序顺序输出节点，结果稳定、便于断言与排查
    const nodesOut: LayoutNode[] = [];
    const stack: MindNode[] = [root];
    while (stack.length > 0) {
      const current: MindNode = stack.pop() as MindNode;
      const placed: LayoutNode | undefined = this.nodeMap.get(current.id);
      if (placed !== undefined) {
        nodesOut.push(placed);
      }
      for (let i = current.children.length - 1; i >= 0; i--) {
        stack.push(current.children[i]);
      }
    }

    let maxRight: number = 0;
    let maxBottom: number = 0;
    this.nodeMap.forEach((node: LayoutNode) => {
      const right: number = node.x + node.width;
      const bottom: number = node.y + node.height;
      if (right > maxRight) {
        maxRight = right;
      }
      if (bottom > maxBottom) {
        maxBottom = bottom;
      }
    });

    const result: LayoutResult = {
      nodes: nodesOut,
      edges: this.edgesOut,
      contentWidth: maxRight + this.cfg.originX,
      contentHeight: maxBottom + this.cfg.originY
    };
    return result;
  }

  /** 在结果集中按 id 查布局节点；查不到返回 null */
  static nodeById(result: LayoutResult, id: string): LayoutNode | null {
    for (let i = 0; i < result.nodes.length; i++) {
      if (result.nodes[i].id === id) {
        return result.nodes[i];
      }
    }
    return null;
  }

  /**
   * 后序递归放置节点，返回该节点的垂直中心 y。
   * 叶子：顺序占用下一个纵向槽位；父节点：中心对齐首个/末个子节点中心。
   */
  private placeNode(node: MindNode, depth: number): number {
    const x: number = this.cfg.originX + depth * (this.cfg.nodeWidth + this.cfg.hGap);
    const visibleChildren: MindNode[] = node.collapsed ? [] : node.children;

    let centerY: number = 0;
    if (visibleChildren.length === 0) {
      const y: number = this.cursorY;
      centerY = y + this.cfg.nodeHeight / 2;
      this.cursorY += this.cfg.nodeHeight + this.cfg.vGap;
      this.putNode(node.id, x, y, depth);
    } else {
      let firstChildCenter: number = 0;
      let lastChildCenter: number = 0;
      for (let i = 0; i < visibleChildren.length; i++) {
        const childCenter: number = this.placeNode(visibleChildren[i], depth + 1);
        if (i === 0) {
          firstChildCenter = childCenter;
        }
        lastChildCenter = childCenter;
      }
      centerY = (firstChildCenter + lastChildCenter) / 2;
      const y: number = centerY - this.cfg.nodeHeight / 2;
      this.putNode(node.id, x, y, depth);

      // 父节点已就位，生成到每个可见子节点的连线锚点
      for (let i = 0; i < visibleChildren.length; i++) {
        const child: MindNode = visibleChildren[i];
        const childLayout: LayoutNode | undefined = this.nodeMap.get(child.id);
        if (childLayout === undefined) {
          continue;
        }
        const edge: Edge = {
          fromId: node.id,
          toId: child.id,
          fromX: x + this.cfg.nodeWidth,
          fromY: centerY,
          toX: childLayout.x,
          toY: childLayout.y + this.cfg.nodeHeight / 2
        };
        this.edgesOut.push(edge);
      }
    }
    return centerY;
  }

  private putNode(id: string, x: number, y: number, depth: number): void {
    const layoutNode: LayoutNode = {
      id: id,
      x: x,
      y: y,
      width: this.cfg.nodeWidth,
      height: this.cfg.nodeHeight,
      depth: depth
    };
    this.nodeMap.set(id, layoutNode);
  }
}
