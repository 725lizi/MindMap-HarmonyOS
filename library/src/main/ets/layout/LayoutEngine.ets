import { MindNode } from '../model/MindNode';
import { LayoutConfig, LayoutNode, Edge, LayoutResult } from './LayoutTypes';

/**
 * 子树轮廓：以「本子树根节点的中心 = 0」为坐标系，
 * 按相对深度 k（0 = 根节点自己）记录该列最顶 / 最底的节点中心。
 * 兄弟子树逐层比对轮廓，就能精确求出「整体下移多少」才不与已摆放子树重叠。
 */
interface SubtreeProfile {
  top: number[];
  bottom: number[];
}

/**
 * LayoutEngine —— 紧凑树形布局引擎（纯逻辑，不依赖 UI，核心卖点，全部坐标可单测）。
 *
 * 算法（后序 + 轮廓下移，复杂度 O(n·深度)）：
 * 1. 水平列由深度决定（铁律 x = originX + depth*(nodeWidth+hGap)），因此只需排纵向中心；
 *    同列（同深度）的节点卡片才有可能重叠，兄弟子树只需在「共享的相对深度」上互相避让。
 * 2. 后序遍历每棵子树，返回 SubtreeProfile（每相对深度的最顶/最底中心）。
 * 3. 摆放某父节点的子节点时：第一棵子树的根中心定为 0；对后续每棵新子树，
 *    在它出现的每一个相对深度上与「已摆放子树的累积底轮廓」比对，
 *    需要的下移量 = 底轮廓 − 新子树顶轮廓 + (nodeHeight+vGap)，取所有深度的最大值，
 *    整棵子树一次性下移，避免每层单独让位造成的缝隙（G4 压缩）。
 * 4. 父中心 = 首、末子节点中心均值；叶/折叠节点即一个轮廓点。
 * 5. 再把全树按「最顶节点中心 = originY + nodeHeight/2」整体平移到画布原点；
 *    连线锚点 = 父右中点 → 子左中点；节点按前序输出。
 *
 * 纯函数语义：不修改入参 MindNode 树、无实例残留状态，相同输入必得相同输出。
 */
export class LayoutEngine {
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
   * @param root  树根（只读；collapsed=true 的节点其整棵子树不参与布局）
   * @param config 布局参数，缺省使用 defaultConfig()
   */
  layout(root: MindNode, config?: LayoutConfig): LayoutResult {
    const cfg: LayoutConfig = config === undefined ? LayoutEngine.defaultConfig() : config;
    const step: number = cfg.nodeWidth + cfg.hGap;
    const halfHeight: number = cfg.nodeHeight / 2;
    // nodeId -> 该节点各可见子节点的根中心偏移（相对父节点中心，按子节点顺序）
    const offsetsById: Map<string, number[]> = new Map<string, number[]>();

    this.placeSubtree(root, cfg, offsetsById);

    // 第一遍：求所有节点中心相对树根的 min / max（用于整体平移到原点）
    const nodeStack: MindNode[] = [root];
    const relStack: number[] = [0];
    let minRel: number = 0;
    let maxRel: number = 0;
    while (nodeStack.length > 0) {
      const current: MindNode = nodeStack.pop() as MindNode;
      const rel: number = relStack.pop() as number;
      if (rel < minRel) {
        minRel = rel;
      }
      if (rel > maxRel) {
        maxRel = rel;
      }
      const offsets: number[] = offsetsById.get(current.id) as number[];
      const kids: MindNode[] = current.collapsed ? [] : current.children;
      for (let i = kids.length - 1; i >= 0; i--) {
        nodeStack.push(kids[i]);
        relStack.push(rel + offsets[i]);
      }
    }
    // 让全图最顶节点的卡片上沿恰好落在 originY
    const shift: number = cfg.originY + halfHeight - minRel;

    // 第二遍：前序输出节点与连线，并统计包围盒
    const nodesOut: LayoutNode[] = [];
    const edgesOut: Edge[] = [];
    let maxRight: number = 0;
    let maxBottom: number = 0;
    const stNode: MindNode[] = [root];
    const stRel: number[] = [0];
    const stDepth: number[] = [0];
    while (stNode.length > 0) {
      const current: MindNode = stNode.pop() as MindNode;
      const rel: number = stRel.pop() as number;
      const depth: number = stDepth.pop() as number;
      const x: number = cfg.originX + depth * step;
      const centerY: number = rel + shift;
      const y: number = centerY - halfHeight;
      const nodeOut: LayoutNode = {
        id: current.id,
        x: x,
        y: y,
        width: cfg.nodeWidth,
        height: cfg.nodeHeight,
        depth: depth
      };
      nodesOut.push(nodeOut);
      if (x + cfg.nodeWidth > maxRight) {
        maxRight = x + cfg.nodeWidth;
      }
      if (centerY + halfHeight > maxBottom) {
        maxBottom = centerY + halfHeight;
      }
      const offsets: number[] = offsetsById.get(current.id) as number[];
      const kids: MindNode[] = current.collapsed ? [] : current.children;
      // 父 → 每个可见子节点：右中点 → 左中点，按子节点顺序推进，保证首边 = 根→长子
      for (let i = 0; i < kids.length; i++) {
        const child: MindNode = kids[i];
        const childRel: number = rel + offsets[i];
        const edge: Edge = {
          fromId: current.id,
          toId: child.id,
          fromX: x + cfg.nodeWidth,
          fromY: centerY,
          toX: cfg.originX + (depth + 1) * step,
          toY: childRel + shift
        };
        edgesOut.push(edge);
      }
      // 反向入栈，弹栈顺序即前序：根 → 各子树按序
      for (let i = kids.length - 1; i >= 0; i--) {
        stNode.push(kids[i]);
        stRel.push(rel + offsets[i]);
        stDepth.push(depth + 1);
      }
    }

    const result: LayoutResult = {
      nodes: nodesOut,
      edges: edgesOut,
      contentWidth: maxRight + cfg.originX,
      contentHeight: maxBottom + cfg.originY
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
   * 后序摆放一棵子树：先摆所有可见子节点，返回本子树轮廓；子节点根中心相对本节点中心的
   * 偏移写入 offsetsById（键为节点 id，树内 id 唯一）。
   */
  private placeSubtree(node: MindNode, cfg: LayoutConfig, offsetsById: Map<string, number[]>): SubtreeProfile {
    const kids: MindNode[] = node.collapsed ? [] : node.children;
    if (kids.length === 0) {
      offsetsById.set(node.id, []);
      const leaf: SubtreeProfile = { top: [0], bottom: [0] };
      return leaf;
    }
    // 1) 后序摆每棵子子树，拿到轮廓
    const profiles: SubtreeProfile[] = [];
    for (let i = 0; i < kids.length; i++) {
      profiles.push(this.placeSubtree(kids[i], cfg, offsetsById));
    }
    // 2) 纵向堆叠子节点：第一棵子树的根中心 = 0；每棵新子树整体下移，
    //    下移量 = max(各共享相对深度: 已摆底轮廓 − 新子树顶轮廓) + (高 + 间距)
    const minGap: number = cfg.nodeHeight + cfg.vGap;
    const rootOffsetInFrame: number[] = [0];
    const bandTop: number[] = [];
    const bandBottom: number[] = [];
    for (let k = 0; k < profiles[0].top.length; k++) {
      bandTop.push(profiles[0].top[k]);
      bandBottom.push(profiles[0].bottom[k]);
    }
    for (let i = 1; i < kids.length; i++) {
      const p: SubtreeProfile = profiles[i];
      let shiftDown: number = 0;
      for (let k = 0; k < p.top.length; k++) {
        if (k < bandBottom.length) {
          const need: number = bandBottom[k] - p.top[k] + minGap;
          if (need > shiftDown) {
            shiftDown = need;
          }
        }
      }
      rootOffsetInFrame.push(shiftDown);
      for (let k = 0; k < p.top.length; k++) {
        const shiftedTop: number = p.top[k] + shiftDown;
        const shiftedBottom: number = p.bottom[k] + shiftDown;
        if (k < bandTop.length) {
          if (shiftedTop < bandTop[k]) {
            bandTop[k] = shiftedTop;
          }
          if (shiftedBottom > bandBottom[k]) {
            bandBottom[k] = shiftedBottom;
          }
        } else {
          bandTop.push(shiftedTop);
          bandBottom.push(shiftedBottom);
        }
      }
    }
    // 3) 父中心 = 首、末子中心均值；换算为相对父中心的偏移
    const parentCenterInFrame: number = rootOffsetInFrame[kids.length - 1] / 2;
    const childOffsets: number[] = [];
    for (let i = 0; i < kids.length; i++) {
      childOffsets.push(rootOffsetInFrame[i] - parentCenterInFrame);
    }
    offsetsById.set(node.id, childOffsets);
    // 4) 由子轮廓折叠出本子树轮廓：相对深度 0 只有根（0），深度 k>=1 取各子节点 k-1 层的外包
    const top: number[] = [0];
    const bottom: number[] = [0];
    for (let i = 0; i < kids.length; i++) {
      const p: SubtreeProfile = profiles[i];
      const offset: number = childOffsets[i];
      for (let k = 0; k < p.top.length; k++) {
        const depth: number = k + 1;
        const shiftedTop: number = offset + p.top[k];
        const shiftedBottom: number = offset + p.bottom[k];
        if (top.length <= depth) {
          top.push(shiftedTop);
          bottom.push(shiftedBottom);
        } else {
          if (shiftedTop < top[depth]) {
            top[depth] = shiftedTop;
          }
          if (shiftedBottom > bottom[depth]) {
            bottom[depth] = shiftedBottom;
          }
        }
      }
    }
    const profile: SubtreeProfile = { top: top, bottom: bottom };
    return profile;
  }
}
