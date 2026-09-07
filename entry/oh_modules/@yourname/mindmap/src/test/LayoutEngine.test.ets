import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { MindNode } from '../main/ets/model/MindNode';
import { LayoutEngine } from '../main/ets/layout/LayoutEngine';
import { LayoutConfig, LayoutResult, LayoutNode } from '../main/ets/layout/LayoutTypes';

function configForTest(): LayoutConfig {
  // 与默认值一致但显式写出，黄金用例的期望值全部基于它
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

function rootWithThreeChildren(): MindNode {
  const root: MindNode = new MindNode('r', '根');
  root.addChild(new MindNode('a', 'A'));
  root.addChild(new MindNode('b', 'B'));
  root.addChild(new MindNode('c', 'C'));
  return root;
}

export default function layoutEngineTest() {
  describe('LayoutEngine', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('singleRoot_shouldPlaceAtOrigin', 0, () => {
      const engine: LayoutEngine = new LayoutEngine();
      const result: LayoutResult = engine.layout(new MindNode('r', '根'), configForTest());
      expect(result.nodes.length).assertEqual(1);
      const root: LayoutNode = result.nodes[0];
      expect(root.x).assertEqual(24);
      expect(root.y).assertEqual(24);
      expect(root.width).assertEqual(160);
      expect(root.height).assertEqual(44);
      expect(root.depth).assertEqual(0);
      expect(result.edges.length).assertEqual(0);
    });

    it('sameLevelChildren_shouldAlignXAndNotOverlap', 0, () => {
      const engine: LayoutEngine = new LayoutEngine();
      const result: LayoutResult = engine.layout(rootWithThreeChildren(), configForTest());
      const a: LayoutNode = LayoutEngine.nodeById(result, 'a') as LayoutNode;
      const b: LayoutNode = LayoutEngine.nodeById(result, 'b') as LayoutNode;
      const c: LayoutNode = LayoutEngine.nodeById(result, 'c') as LayoutNode;
      // 同层 x 对齐：24 + 1*(160+48) = 232
      expect(a.x).assertEqual(232);
      expect(b.x).assertEqual(232);
      expect(c.x).assertEqual(232);
      // 叶子槽位：24、84、144，间距 = 高44 + vGap16 = 60
      expect(a.y).assertEqual(24);
      expect(b.y).assertEqual(84);
      expect(c.y).assertEqual(144);
      // 子树不重叠：b 顶部不早于 a 底部 + vGap
      expect(b.y - (a.y + 44)).assertEqual(16);
      expect(result.edges.length).assertEqual(3);
    });

    it('parent_shouldCenterBetweenFirstAndLastChild', 0, () => {
      const engine: LayoutEngine = new LayoutEngine();
      const result: LayoutResult = engine.layout(rootWithThreeChildren(), configForTest());
      const root: LayoutNode = result.nodes[0];
      // a 中心 46、c 中心 166，父中心 = 106，y = 106 - 22 = 84
      expect(root.y).assertEqual(84);
    });

    it('x_shouldGrowByDepth', 0, () => {
      const root: MindNode = new MindNode('r', '根');
      const a: MindNode = new MindNode('a', 'A');
      const a1: MindNode = new MindNode('a1', 'A1');
      a.addChild(a1);
      root.addChild(a);
      const engine: LayoutEngine = new LayoutEngine();
      const result: LayoutResult = engine.layout(root, configForTest());
      expect((LayoutEngine.nodeById(result, 'r') as LayoutNode).x).assertEqual(24);
      expect((LayoutEngine.nodeById(result, 'a') as LayoutNode).x).assertEqual(232);
      // depth=2：24 + 2*208 = 440
      expect((LayoutEngine.nodeById(result, 'a1') as LayoutNode).x).assertEqual(440);
    });

    it('collapsedNode_shouldBeTreatedAsLeaf', 0, () => {
      const root: MindNode = rootWithThreeChildren();
      root.collapsed = true;
      const engine: LayoutEngine = new LayoutEngine();
      const result: LayoutResult = engine.layout(root, configForTest());
      expect(result.nodes.length).assertEqual(1);
      expect(result.edges.length).assertEqual(0);
      expect(result.nodes[0].y).assertEqual(24);
    });

    it('edgeAnchors_shouldConnectRightOfParentToLeftOfChild', 0, () => {
      const engine: LayoutEngine = new LayoutEngine();
      const result: LayoutResult = engine.layout(rootWithThreeChildren(), configForTest());
      const edge = result.edges[0];
      expect(edge.fromId).assertEqual('r');
      expect(edge.toId).assertEqual('a');
      expect(edge.fromX).assertEqual(184); // 24 + 160
      expect(edge.toX).assertEqual(232);
    });

    it('sameInput_shouldAlwaysProduceSameOutput', 0, () => {
      const engine1: LayoutEngine = new LayoutEngine();
      const engine2: LayoutEngine = new LayoutEngine();
      const r1: LayoutResult = engine1.layout(rootWithThreeChildren(), configForTest());
      const r2: LayoutResult = engine2.layout(rootWithThreeChildren(), configForTest());
      expect(JSON.stringify(r1)).assertEqual(JSON.stringify(r2));
      expect(r1.contentWidth > 0).assertTrue();
      expect(r1.contentHeight > 0);
    });
  });
}
