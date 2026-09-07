import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { MindNode } from '../main/ets/model/MindNode';

// 测试夹具放模块顶层（ArkTS 禁止在 describe 回调内嵌套声明函数）
function buildThreeLevelTree(): MindNode {
  const root: MindNode = new MindNode('r', '根');
  const a: MindNode = new MindNode('a', 'A');
  const b: MindNode = new MindNode('b', 'B');
  const a1: MindNode = new MindNode('a1', 'A1');
  root.addChild(a);
  root.addChild(b);
  a.addChild(a1);
  return root;
}

export default function mindNodeTest() {
  describe('MindNode', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('create_shouldBeLeafRootWithZeroDepth', 0, () => {
      const node: MindNode = MindNode.create('n1', '节点');
      expect(node.id).assertEqual('n1');
      expect(node.text).assertEqual('节点');
      expect(node.isLeaf()).assertTrue();
      expect(node.isRoot()).assertTrue();
      expect(node.depth()).assertEqual(0);
      expect(node.childCount()).assertEqual(0);
    });

    it('addChild_shouldSetBackPointerAndOrder', 0, () => {
      const root: MindNode = new MindNode('r', '根');
      const a: MindNode = new MindNode('a', 'A');
      const b: MindNode = new MindNode('b', 'B');
      root.addChild(a);
      root.addChild(b);
      expect(root.childCount()).assertEqual(2);
      expect(root.children[0].id).assertEqual('a');
      expect(a.parent === root).assertTrue();
      expect(root.indexOfChild(b)).assertEqual(1);
      expect(root.isLeaf()).assertFalse();
    });

    it('depth_shouldCountAncestors', 0, () => {
      const root: MindNode = buildThreeLevelTree();
      const a1: MindNode = root.children[0].children[0];
      expect(a1.id).assertEqual('a1');
      expect(a1.depth()).assertEqual(2);
      expect(root.children[1].depth()).assertEqual(1);
    });

    it('removeChild_shouldClearBackPointer', 0, () => {
      const root: MindNode = new MindNode('r', '根');
      const a: MindNode = new MindNode('a', 'A');
      root.addChild(a);
      const removed: boolean = root.removeChild(a);
      expect(removed).assertTrue();
      expect(root.childCount()).assertEqual(0);
      expect(a.parent).assertNull();
      expect(root.removeChild(a)).assertFalse();
    });

    it('addChild_shouldDetachFromPreviousParent', 0, () => {
      const root: MindNode = buildThreeLevelTree();
      const a1: MindNode = root.children[0].children[0];
      // 把 a1 从 a 名下改挂到 root，旧父节点应自动摘除，保证只有一个父亲
      root.addChild(a1);
      expect(root.children[0].childCount()).assertEqual(0);
      expect(root.childCount()).assertEqual(3);
      expect(a1.parent === root).assertTrue();
    });

    it('insertChildAt_shouldKeepOrder', 0, () => {
      const root: MindNode = new MindNode('r', '根');
      const a: MindNode = new MindNode('a', 'A');
      const c: MindNode = new MindNode('c', 'C');
      root.addChild(a);
      root.insertChildAt(1, c);
      expect(root.children[0].id).assertEqual('a');
      expect(root.children[1].id).assertEqual('c');
      root.insertChildAt(0, new MindNode('z', 'Z'));
      expect(root.children[0].id).assertEqual('z');
    });

    it('insertChildAt_outOfRange_shouldThrow', 0, () => {
      const root: MindNode = new MindNode('r', '根');
      let thrown: boolean = false;
      try {
        root.insertChildAt(5, new MindNode('x', 'X'));
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });

    it('addSelfAsChild_shouldThrow', 0, () => {
      const root: MindNode = new MindNode('r', '根');
      let thrown: boolean = false;
      try {
        root.addChild(root);
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });

    it('addAncestorAsChild_shouldThrowToAvoidCycle', 0, () => {
      const root: MindNode = buildThreeLevelTree();
      const a1: MindNode = root.children[0].children[0];
      let thrown: boolean = false;
      try {
        // 试图把祖父 root 挂为孙子 a1 的子节点，会成环，必须拒绝
        a1.addChild(root);
      } catch (e) {
        thrown = true;
      }
      expect(thrown).assertTrue();
    });

    it('indexOfChild_notChild_shouldReturnMinusOne', 0, () => {
      const root: MindNode = new MindNode('r', '根');
      const outsider: MindNode = new MindNode('o', '外');
      expect(root.indexOfChild(outsider)).assertEqual(-1);
    });
  });
}
