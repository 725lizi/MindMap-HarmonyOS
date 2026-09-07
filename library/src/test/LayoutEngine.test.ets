import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { MindNode } from '../main/ets/model/MindNode';
import { LayoutEngine } from '../main/ets/layout/LayoutEngine';
import { LayoutConfig, LayoutResult, LayoutNode } from '../main/ets/layout/LayoutTypes';

/** 与 LayoutEngine.defaultConfig() 一致，但显式写出：黄金用例期望值都基于它 */
function configForTest(): LayoutConfig {
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

/** G2：r → [a, b, c]，三片叶子 */
function rootWithThreeChildren(): MindNode {
  const root: MindNode = new MindNode('r', '根');
  root.addChild(new MindNode('a', 'A'));
  root.addChild(new MindNode('b', 'B'));
  root.addChild(new MindNode('c', 'C'));
  return root;
}

/** G4 压缩核心：r → [A, B]; A → [a1, a2]; a1 → a11 */
function rootCompression(): MindNode {
  const r: MindNode = new MindNode('r', 'R');
  const A: MindNode = new MindNode('A', 'A');
  const B: MindNode = new MindNode('B', 'B');
  r.addChild(A);
  r.addChild(B);
  const a1: MindNode = new MindNode('a1', 'a1');
  A.addChild(a1);
  A.addChild(new MindNode('a2', 'a2'));
  a1.addChild(new MindNode('a11', 'a11'));
  return r;
}

/**
 * 自造不对称树 X1：r → [A, B, C]；A → [a1, a2]；a1 → a11。
 * 兄弟子树深度差 = 2（A 子树 3 层 vs B/C 叶子 1 层）；r 的一层有 3 个兄弟。
 */
function rootAsymX1(): MindNode {
  const r: MindNode = new MindNode('r', 'R');
  const A: MindNode = new MindNode('A', 'A');
  const B: MindNode = new MindNode('B', 'B');
  const C: MindNode = new MindNode('C', 'C');
  r.addChild(A);
  r.addChild(B);
  r.addChild(C);
  const a1: MindNode = new MindNode('a1', 'a1');
  A.addChild(a1);
  A.addChild(new MindNode('a2', 'a2'));
  a1.addChild(new MindNode('a11', 'a11'));
  return r;
}

/**
 * 自造不对称树 X2：r → [A, B]；A → [a1, a2, a3]；a1 → a11 → a111。
 * 兄弟子树深度差 = 2（a1 子树 3 层 vs a2/a3 叶子）、= 3（A 子树 4 层 vs B 叶子）；
 * A 的一层有 3 个兄弟。
 */
function rootAsymX2(): MindNode {
  const r: MindNode = new MindNode('r', 'R');
  const A: MindNode = new MindNode('A', 'A');
  const B: MindNode = new MindNode('B', 'B');
  r.addChild(A);
  r.addChild(B);
  const a1: MindNode = new MindNode('a1', 'a1');
  A.addChild(a1);
  A.addChild(new MindNode('a2', 'a2'));
  A.addChild(new MindNode('a3', 'a3'));
  const a11: MindNode = new MindNode('a11', 'a11');
  a1.addChild(a11);
  a11.addChild(new MindNode('a111', 'a111'));
  return r;
}

function centerOf(node: LayoutNode): number {
  return node.y + node.height / 2;
}

/** 断言某节点出现在 (x, y, depth)；找不到或坐标不符直接使当前用例失败 */
function assertNodeAt(result: LayoutResult, id: string, x: number, y: number, depth: number): void {
  const found: LayoutNode | null = LayoutEngine.nodeById(result, id);
  expect(found !== null).assertTrue();
  const node: LayoutNode = found as LayoutNode;
  expect(node.x).assertEqual(x);
  expect(node.y).assertEqual(y);
  expect(node.depth).assertEqual(depth);
  expect(node.width).assertEqual(160);
  expect(node.height).assertEqual(44);
}

/** 树的可视前序 id 列表（跳过 collapsed 子树） */
function visibleIds(root: MindNode): string[] {
  const out: string[] = [];
  const stack: MindNode[] = [root];
  while (stack.length > 0) {
    const current: MindNode = stack.pop() as MindNode;
    out.push(current.id);
    const kids: MindNode[] = current.collapsed ? [] : current.children;
    for (let i = kids.length - 1; i >= 0; i--) {
      stack.push(kids[i]);
    }
  }
  return out;
}

/** 全树结构快照（含折叠子树），用于「布局不改入参」校验 */
function snapshotOf(root: MindNode): string {
  const parts: string[] = [];
  const stack: MindNode[] = [root];
  while (stack.length > 0) {
    const current: MindNode = stack.pop() as MindNode;
    parts.push(current.id + '|' + current.text + '|' + (current.collapsed ? '1' : '0') + '|' + current.children.length.toString());
    for (let i = current.children.length - 1; i >= 0; i--) {
      stack.push(current.children[i]);
    }
  }
  return parts.join(';');
}

function sameStringArray(a: string[], b: string[]): boolean {
  if (a.length !== b.length) {
    return false;
  }
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) {
      return false;
    }
  }
  return true;
}

/** 随机树生成（固定种子 LCG，结果可复现） */
let randomSeed: number = 20240607;
function resetRandom(seed: number): void {
  randomSeed = seed;
}
function nextInt(lo: number, hi: number): number {
  randomSeed = (randomSeed * 1103515245 + 12345) & 2147483647;
  const span: number = hi - lo + 1;
  return lo + Math.floor((randomSeed / 2147483648) * span);
}

/** 随机造一棵 1..70 节点的树；深度 ≤ 7；每个节点约 30% 概率折叠 */
function randomRoot(): MindNode {
  const root: MindNode = new MindNode('n0', 't0');
  const depthOf: Map<string, number> = new Map<string, number>();
  depthOf.set(root.id, 0);
  const queue: MindNode[] = [root];
  const all: MindNode[] = [root];
  let nextId: number = 1;
  const target: number = nextInt(1, 70);
  const capDepth: number = nextInt(0, 7);
  let head: number = 0;
  while (all.length < target && head < queue.length) {
    const parent: MindNode = queue[head];
    head++;
    const parentDepth: number = depthOf.get(parent.id) as number;
    let kidsCount: number = 0;
    if (parentDepth < capDepth) {
      kidsCount = nextInt(0, 5);
    }
    for (let i = 0; i < kidsCount && all.length < target; i++) {
      const child: MindNode = new MindNode('n' + nextId.toString(), 't');
      nextId++;
      parent.addChild(child);
      all.push(child);
      depthOf.set(child.id, parentDepth + 1);
      queue.push(child);
    }
  }
  for (let i = 0; i < all.length; i++) {
    if (nextInt(0, 9) < 3) {
      all[i].collapsed = true;
    }
  }
  return root;
}

/** 审计状态：六条不变量 + 附加边界，逐棵随机树累计违例 */
interface AuditState {
  total: number;
  sameDepthX: number;
  siblingGap: number;
  sameDepthOverlap: number;
  parentCentered: number;
  determinism: number;
  collapseHidden: number;
  purity: number;
  anchors: number;
  box: number;
}

function newAuditState(): AuditState {
  const state: AuditState = {
    total: 0,
    sameDepthX: 0,
    siblingGap: 0,
    sameDepthOverlap: 0,
    parentCentered: 0,
    determinism: 0,
    collapseHidden: 0,
    purity: 0,
    anchors: 0,
    box: 0
  };
  return state;
}

function bump(state: AuditState, key: string): void {
  state.total++;
  if (key === 'x') {
    state.sameDepthX++;
  } else if (key === 'gap') {
    state.siblingGap++;
  } else if (key === 'overlap') {
    state.sameDepthOverlap++;
  } else if (key === 'center') {
    state.parentCentered++;
  } else if (key === 'det') {
    state.determinism++;
  } else if (key === 'hide') {
    state.collapseHidden++;
  } else if (key === 'pure') {
    state.purity++;
  } else if (key === 'anchor') {
    state.anchors++;
  } else if (key === 'box') {
    state.box++;
  }
}

/** 对一棵随机树执行布局并核对全部不变量 */
function auditTree(root: MindNode, engine: LayoutEngine, cfg: LayoutConfig, state: AuditState): void {
  const before: string = snapshotOf(root);
  const result: LayoutResult = engine.layout(root, cfg);
  const second: LayoutResult = engine.layout(root, cfg);
  const step: number = cfg.nodeWidth + cfg.hGap;
  const gapC: number = cfg.nodeHeight + cfg.vGap;

  // 不变量5：确定性（同一棵树两次布局结果逐字节一致）
  if (JSON.stringify(result) !== JSON.stringify(second)) {
    bump(state, 'det');
  }
  // 纯函数：入参树结构未被改动
  if (snapshotOf(root) !== before) {
    bump(state, 'pure');
  }

  // 索引：模型节点 / 布局节点
  const modelById: Map<string, MindNode> = new Map<string, MindNode>();
  const layoutById: Map<string, LayoutNode> = new Map<string, LayoutNode>();
  {
    const stack: MindNode[] = [root];
    while (stack.length > 0) {
      const current: MindNode = stack.pop() as MindNode;
      modelById.set(current.id, current);
      for (let i = current.children.length - 1; i >= 0; i--) {
        stack.push(current.children[i]);
      }
    }
  }
  for (let i = 0; i < result.nodes.length; i++) {
    layoutById.set(result.nodes[i].id, result.nodes[i]);
  }

  // 不变量6：折叠隐藏后代 —— 结果恰好等于「模型可见前序」，无幽灵节点、无顺序错乱
  const modelVisible: string[] = visibleIds(root);
  const resultIds: string[] = [];
  for (let i = 0; i < result.nodes.length; i++) {
    resultIds.push(result.nodes[i].id);
  }
  if (!sameStringArray(modelVisible, resultIds)) {
    bump(state, 'hide');
  }
  for (let i = 0; i < result.edges.length; i++) {
    const e = result.edges[i];
    const parent: MindNode | null = modelById.get(e.fromId) as MindNode | null;
    const child: MindNode | null = modelById.get(e.toId) as MindNode | null;
    if (parent === null || child === null || parent.collapsed || child.parent !== parent) {
      bump(state, 'hide');
    }
    // 附加：锚点 = 父右中点 → 子左中点
    const pn: LayoutNode | null = layoutById.get(e.fromId) as LayoutNode | null;
    const cn: LayoutNode | null = layoutById.get(e.toId) as LayoutNode | null;
    if (pn === null || cn === null) {
      bump(state, 'anchor');
      continue;
    }
    if (e.fromX !== pn.x + pn.width || e.fromY !== centerOf(pn) || e.toX !== cn.x || e.toY !== centerOf(cn)) {
      bump(state, 'anchor');
    }
  }

  // 按深度分组（线性扫 + 追加，避免依赖 Map 遍历）
  const groupDepths: number[] = [];
  const groupLists: LayoutNode[][] = [];
  for (let i = 0; i < result.nodes.length; i++) {
    const node: LayoutNode = result.nodes[i];
    let g: number = -1;
    for (let j = 0; j < groupDepths.length; j++) {
      if (groupDepths[j] === node.depth) {
        g = j;
        break;
      }
    }
    if (g < 0) {
      groupDepths.push(node.depth);
      const fresh: LayoutNode[] = [];
      fresh.push(node);
      groupLists.push(fresh);
    } else {
      groupLists[g].push(node);
    }
  }
  // 不变量1：同深度 x 相同，且 = originX + depth * (宽+水平间距)
  // 不变量3：同深度卡片两两不重叠，且间隙 ≥ vGap
  for (let g = 0; g < groupDepths.length; g++) {
    const depth: number = groupDepths[g];
    const list: LayoutNode[] = groupLists[g];
    const wantX: number = cfg.originX + depth * step;
    for (let i = 0; i < list.length; i++) {
      if (list[i].x !== wantX) {
        bump(state, 'x');
      }
    }
    for (let i = 0; i < list.length; i++) {
      for (let j = i + 1; j < list.length; j++) {
        const d: number = Math.abs(centerOf(list[i]) - centerOf(list[j]));
        if (d < gapC - 1e-9) {
          bump(state, 'overlap');
        }
      }
    }
  }

  // 不变量2：同一父节点的相邻可见子节点间距 ≥ nodeHeight + vGap
  // 不变量4：父中心 = 首末子中心均值
  for (let i = 0; i < result.nodes.length; i++) {
    const node: LayoutNode = result.nodes[i];
    const mn: MindNode | null = modelById.get(node.id) as MindNode | null;
    if (mn === null || mn.collapsed) {
      continue;
    }
    const kids: MindNode[] = mn.children;
    const visibleKids: MindNode[] = [];
    for (let k = 0; k < kids.length; k++) {
      if (layoutById.has(kids[k].id)) {
        visibleKids.push(kids[k]);
      }
    }
    if (visibleKids.length === 0) {
      continue;
    }
    const first: LayoutNode = layoutById.get(visibleKids[0].id) as LayoutNode;
    const last: LayoutNode = layoutById.get(visibleKids[visibleKids.length - 1].id) as LayoutNode;
    const mid: number = (centerOf(first) + centerOf(last)) / 2;
    if (Math.abs(centerOf(node) - mid) > 1e-9) {
      bump(state, 'center');
    }
    for (let k = 1; k < visibleKids.length; k++) {
      const prev: LayoutNode = layoutById.get(visibleKids[k - 1].id) as LayoutNode;
      const curr: LayoutNode = layoutById.get(visibleKids[k].id) as LayoutNode;
      if (centerOf(curr) - centerOf(prev) < gapC - 1e-9) {
        bump(state, 'gap');
      }
    }
  }

  // 附加：所有节点都在包围盒内
  for (let i = 0; i < result.nodes.length; i++) {
    const node: LayoutNode = result.nodes[i];
    if (node.x < 0 || node.y < 0 ||
      node.x + node.width > result.contentWidth ||
      node.y + node.height > result.contentHeight) {
      bump(state, 'box');
    }
  }
}

export default function layoutEngineTest() {
  describe('LayoutEngine', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    // ============ G1 单根 ============
    it('G1_singleRoot_shouldPlaceAtOriginWithEmptyEdges', 0, () => {
      const engine: LayoutEngine = new LayoutEngine();
      const result: LayoutResult = engine.layout(new MindNode('r', '根'), configForTest());
      expect(result.nodes.length).assertEqual(1);
      assertNodeAt(result, 'r', 24, 24, 0);
      expect(result.edges.length).assertEqual(0);
      expect(result.contentWidth).assertEqual(208);
      expect(result.contentHeight).assertEqual(92);
    });

    // ============ G2 三子 ============
    it('G2_threeLeaves_shouldStackAndCenter', 0, () => {
      const engine: LayoutEngine = new LayoutEngine();
      const result: LayoutResult = engine.layout(rootWithThreeChildren(), configForTest());
      assertNodeAt(result, 'a', 232, 24, 1);
      assertNodeAt(result, 'b', 232, 84, 1);
      assertNodeAt(result, 'c', 232, 144, 1);
      assertNodeAt(result, 'r', 24, 84, 0);
      // 首边：父右中点(184, 106) → 子左中点(232, 46)
      expect(result.edges.length).assertEqual(3);
      expect(result.edges[0].fromId).assertEqual('r');
      expect(result.edges[0].toId).assertEqual('a');
      expect(result.edges[0].fromX).assertEqual(184);
      expect(result.edges[0].toX).assertEqual(232);
      expect(result.edges[0].fromY).assertEqual(106);
      expect(result.edges[0].toY).assertEqual(46);
    });

    // ============ G3 深度链 ============
    it('G3_chain_shouldKeepSameY', 0, () => {
      const root: MindNode = new MindNode('r', '根');
      const a: MindNode = new MindNode('a', 'A');
      const a1: MindNode = new MindNode('a1', 'A1');
      a.addChild(a1);
      root.addChild(a);
      const engine: LayoutEngine = new LayoutEngine();
      const result: LayoutResult = engine.layout(root, configForTest());
      assertNodeAt(result, 'r', 24, 24, 0);
      assertNodeAt(result, 'a', 232, 24, 1);
      assertNodeAt(result, 'a1', 440, 24, 2);
    });

    // ============ G4 压缩核心（旧算法 B=144、高 212，新算法必须更紧凑） ============
    it('G4_compression_shouldTuckBeneathA', 0, () => {
      const engine: LayoutEngine = new LayoutEngine();
      const result: LayoutResult = engine.layout(rootCompression(), configForTest());
      // 手算过程：a11 顶到原点(24)；A 子树底 = a2 中心 106；
      // B 只与 A 共享第 0 相对深度（叶子无更深层），紧贴 A 下移 60 → 中心 136 → y 114
      assertNodeAt(result, 'r', 24, 84, 0);
      assertNodeAt(result, 'A', 232, 54, 1);
      assertNodeAt(result, 'B', 232, 114, 1);
      assertNodeAt(result, 'a1', 440, 24, 2);
      assertNodeAt(result, 'a2', 440, 84, 2);
      assertNodeAt(result, 'a11', 648, 24, 3);
      expect(result.contentWidth).assertEqual(832);
      expect(result.contentHeight).assertEqual(182);
      expect(result.edges.length).assertEqual(5);
      // 压缩回归：B 必须高于旧算法的 144（旧高 212 → 新高 182）
      const b: LayoutNode = LayoutEngine.nodeById(result, 'B') as LayoutNode;
      expect(b.y < 144).assertTrue();
      expect(result.contentHeight < 212).assertTrue();
    });

    // ============ G5 折叠根 ============
    it('G5_collapsedRoot_shouldShrinkToSingleNode', 0, () => {
      const root: MindNode = rootWithThreeChildren();
      root.collapsed = true;
      const engine: LayoutEngine = new LayoutEngine();
      const result: LayoutResult = engine.layout(root, configForTest());
      expect(result.nodes.length).assertEqual(1);
      expect(result.edges.length).assertEqual(0);
      assertNodeAt(result, 'r', 24, 24, 0);
    });

    // ============ X1 自造不对称树 1（手算期望值） ============
    it('X1_asymmetric_deepLeftSiblingCompressed', 0, () => {
      const engine: LayoutEngine = new LayoutEngine();
      const result: LayoutResult = engine.layout(rootAsymX1(), configForTest());
      // 手算：r 中心 = (46+?)/2…先摆 A 子树于顶，B、C 依次让出 60；
      // A 中心 −60、B 0、C +60（相对 r）；A 内 a1 −30、a2 +30；a1/a11 同中心。
      // 全图最顶 a1/a11 中心 46（y=24）→ 平移量 136，得下表。
      assertNodeAt(result, 'r', 24, 114, 0);
      assertNodeAt(result, 'A', 232, 54, 1);
      assertNodeAt(result, 'B', 232, 114, 1);
      assertNodeAt(result, 'C', 232, 174, 1);
      assertNodeAt(result, 'a1', 440, 24, 2);
      assertNodeAt(result, 'a2', 440, 84, 2);
      assertNodeAt(result, 'a11', 648, 24, 3);
      expect(result.contentWidth).assertEqual(832);
      expect(result.contentHeight).assertEqual(242);
      expect(result.edges.length).assertEqual(6);
      // B 与 A 子树同列不重叠：B 上沿 = 114 ≥ A 下沿 54+44 + vGap16 = 114
      const a: LayoutNode = LayoutEngine.nodeById(result, 'A') as LayoutNode;
      const b: LayoutNode = LayoutEngine.nodeById(result, 'B') as LayoutNode;
      expect(b.y - (a.y + 44)).assertEqual(16);
    });

    // ============ X2 自造不对称树 2（手算期望值） ============
    it('X2_asymmetric_threeSiblingsTuckedByContour', 0, () => {
      const engine: LayoutEngine = new LayoutEngine();
      const result: LayoutResult = engine.layout(rootAsymX2(), configForTest());
      // 手算：a1 子树深 3 层与叶子 a2/a3 同父；a2、a3 只与 a1 共享第 0 相对深度，
      // 因而可紧贴（间距 60）而无需让开 a1 的深层链 → 三者中心 −60/0/+60（相对 A）。
      assertNodeAt(result, 'r', 24, 114, 0);
      assertNodeAt(result, 'A', 232, 84, 1);
      assertNodeAt(result, 'B', 232, 144, 1);
      assertNodeAt(result, 'a1', 440, 24, 2);
      assertNodeAt(result, 'a2', 440, 84, 2);
      assertNodeAt(result, 'a3', 440, 144, 2);
      assertNodeAt(result, 'a11', 648, 24, 3);
      assertNodeAt(result, 'a111', 856, 24, 4);
      expect(result.contentWidth).assertEqual(1040);
      expect(result.contentHeight).assertEqual(212);
      expect(result.edges.length).assertEqual(7);
      // 深度差 ≥2 的压缩：a11 链（y=24）与 a2（y=84）分处不同列，互不挤压
      const a2: LayoutNode = LayoutEngine.nodeById(result, 'a2') as LayoutNode;
      const a3: LayoutNode = LayoutEngine.nodeById(result, 'a3') as LayoutNode;
      expect(a3.y - a2.y).assertEqual(60);
    });

    // ============ 前序输出 + 边锚点（覆盖既有契约） ============
    it('preorder_shouldMatchTreeOrderAndAnchorEdges', 0, () => {
      const root: MindNode = rootCompression();
      const engine: LayoutEngine = new LayoutEngine();
      const result: LayoutResult = engine.layout(root, configForTest());
      expect(visibleIds(root).length).assertEqual(result.nodes.length);
      expect(sameStringArray(visibleIds(root), resultIdsOf(result))).assertTrue();
      for (let i = 0; i < result.edges.length; i++) {
        const e = result.edges[i];
        const from: LayoutNode | null = LayoutEngine.nodeById(result, e.fromId);
        const to: LayoutNode | null = LayoutEngine.nodeById(result, e.toId);
        expect(from !== null).assertTrue();
        expect(to !== null).assertTrue();
        const fn: LayoutNode = from as LayoutNode;
        const tn: LayoutNode = to as LayoutNode;
        expect(e.fromX).assertEqual(fn.x + fn.width);
        expect(e.fromY).assertEqual(centerOf(fn));
        expect(e.toX).assertEqual(tn.x);
        expect(e.toY).assertEqual(centerOf(tn));
      }
    });

    it('layout_shouldNotMutateInputTree', 0, () => {
      const root: MindNode = rootCompression();
      const before: string = snapshotOf(root);
      const engine: LayoutEngine = new LayoutEngine();
      engine.layout(root, configForTest());
      expect(snapshotOf(root)).assertEqual(before);
    });

    it('sameInput_shouldAlwaysProduceSameOutput', 0, () => {
      const engine1: LayoutEngine = new LayoutEngine();
      const engine2: LayoutEngine = new LayoutEngine();
      const r1: LayoutResult = engine1.layout(rootWithThreeChildren(), configForTest());
      const r2: LayoutResult = engine2.layout(rootWithThreeChildren(), configForTest());
      expect(JSON.stringify(r1)).assertEqual(JSON.stringify(r2));
      expect(r1.contentWidth > 0).assertTrue();
      expect(r1.contentHeight > 0).assertTrue();
    });

    // ============ 1000 棵随机树 × 6 条不变量，零违例 ============
    it('random1000Trees_sixInvariants_zeroViolations', 0, () => {
      const engine: LayoutEngine = new LayoutEngine();
      const cfg: LayoutConfig = configForTest();
      resetRandom(20240607);
      const state: AuditState = newAuditState();
      for (let t = 0; t < 1000; t++) {
        const root: MindNode = randomRoot();
        auditTree(root, engine, cfg, state);
      }
      expect(state.total).assertEqual(0);
      expect(state.sameDepthX).assertEqual(0);
      expect(state.siblingGap).assertEqual(0);
      expect(state.sameDepthOverlap).assertEqual(0);
      expect(state.parentCentered).assertEqual(0);
      expect(state.determinism).assertEqual(0);
      expect(state.collapseHidden).assertEqual(0);
      expect(state.purity).assertEqual(0);
      expect(state.anchors).assertEqual(0);
      expect(state.box).assertEqual(0);
    });
  });
}

/** result.nodes 的 id 序列 */
function resultIdsOf(result: LayoutResult): string[] {
  const out: string[] = [];
  for (let i = 0; i < result.nodes.length; i++) {
    out.push(result.nodes[i].id);
  }
  return out;
}
