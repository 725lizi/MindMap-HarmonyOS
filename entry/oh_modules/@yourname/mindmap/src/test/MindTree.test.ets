import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { MindTree } from '../main/ets/model/MindTree';
import { MindNode } from '../main/ets/model/MindNode';

// 标准测试树：
//        r
//      / | \
//     a  b  c
//    /|
//  a1 a2
function buildStandardTree(): MindTree {
  const tree: MindTree = new MindTree('根', 'r');
  tree.addChildTo('r', new MindNode('a', 'A'));
  tree.addChildTo('r', new MindNode('b', 'B'));
  tree.addChildTo('r', new MindNode('c', 'C'));
  tree.addChildTo('a', new MindNode('a1', 'A1'));
  tree.addChildTo('a', new MindNode('a2', 'A2'));
  return tree;
}

export default function mindTreeTest() {
  describe('MindTree', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('constructor_shouldHaveRootOnly', 0, () => {
      const tree: MindTree = new MindTree('中心', 'root');
      expect(tree.root.id).assertEqual('root');
      expect(tree.root.text).assertEqual('中心');
      expect(tree.count()).assertEqual(1);
    });

    it('findById_hitAndMiss', 0, () => {
      const tree: MindTree = buildStandardTree();
      expect(tree.findById('a2') !== null).assertTrue();
      expect((tree.findById('a2') as MindNode).text).assertEqual('A2');
      expect(tree.findById('not-exist')).assertNull();
      expect(tree.contains('c')).assertTrue();
      expect(tree.contains('zzz')).assertFalse();
    });

    it('depthOf_shouldReturnDepthOrMinusOne', 0, () => {
      const tree: MindTree = buildStandardTree();
      expect(tree.depthOf('r')).assertEqual(0);
      expect(tree.depthOf('b')).assertEqual(1);
      expect(tree.depthOf('a1')).assertEqual(2);
      expect(tree.depthOf('none')).assertEqual(-1);
    });

    it('pathToRoot_shouldBeOrderedRootToNode', 0, () => {
      const tree: MindTree = buildStandardTree();
      const ids: string[] = tree.pathIdsToRoot('a2');
      expect(ids.length).assertEqual(3);
      expect(ids[0]).assertEqual('r');
      expect(ids[1]).assertEqual('a');
      expect(ids[2]).assertEqual('a2');
      expect(tree.pathIdsToRoot('none').length).assertEqual(0);
    });

    it('preorder_shouldFollowChildrenOrder', 0, () => {
      const tree: MindTree = buildStandardTree();
      const ids: string[] = [];
      const nodes: MindNode[] = tree.preorder();
      for (let i = 0; i < nodes.length; i++) {
        ids.push(nodes[i].id);
      }
      expect(ids.join(',')).assertEqual('r,a,a1,a2,b,c');
    });

    it('breadthFirst_shouldBeLayerOrder', 0, () => {
      const tree: MindTree = buildStandardTree();
      const ids: string[] = [];
      const nodes: MindNode[] = tree.breadthFirst();
      for (let i = 0; i < nodes.length; i++) {
        ids.push(nodes[i].id);
      }
      expect(ids.join(',')).assertEqual('r,a,b,c,a1,a2');
    });

    it('leaves_shouldReturnAllLeafNodes', 0, () => {
      const tree: MindTree = buildStandardTree();
      const leaves: MindNode[] = tree.leaves();
      expect(leaves.length).assertEqual(4);
      expect(leaves[0].id).assertEqual('a1');
      expect(leaves[3].id).assertEqual('c');
    });

    it('count_shouldCountAllNodes', 0, () => {
      const tree: MindTree = buildStandardTree();
      expect(tree.count()).assertEqual(6);
    });

    it('createNode_shouldGenerateDistinctIds', 0, () => {
      const tree: MindTree = new MindTree('根', 'r');
      const n1: MindNode = tree.createNode('1');
      const n2: MindNode = tree.createNode('2');
      expect(n1.id === n2.id).assertFalse();
    });

    it('addChildTo_missingParent_shouldReturnFalse', 0, () => {
      const tree: MindTree = new MindTree('根', 'r');
      expect(tree.addChildTo('ghost', new MindNode('x', 'X'))).assertFalse();
      expect(tree.count()).assertEqual(1);
    });

    it('appendNewChild_shouldAttachAndReturnNode', 0, () => {
      const tree: MindTree = new MindTree('根', 'r');
      const created: MindNode | null = tree.appendNewChild('r', '子');
      expect(created !== null).assertTrue();
      expect(tree.count()).assertEqual(2);
      expect(tree.root.children[0].text).assertEqual('子');
      expect(tree.appendNewChild('ghost', 'X')).assertNull();
    });

    it('insertSiblingAfter_shouldInsertAtRightPosition', 0, () => {
      const tree: MindTree = buildStandardTree();
      const sibling: MindNode | null = tree.insertSiblingAfter('a', 'A-new');
      expect(sibling !== null).assertTrue();
      expect(tree.root.children[1].text).assertEqual('A-new');
      // 根没有兄弟
      expect(tree.insertSiblingAfter('r', 'X')).assertNull();
    });

    it('remove_shouldDropSubtreeButProtectRoot', 0, () => {
      const tree: MindTree = buildStandardTree();
      expect(tree.remove('r')).assertFalse();
      expect(tree.remove('none')).assertFalse();
      // 删除 a，连同 a1/a2 整棵子树一起消失
      expect(tree.remove('a')).assertTrue();
      expect(tree.contains('a')).assertFalse();
      expect(tree.contains('a1')).assertFalse();
      expect(tree.contains('a2')).assertFalse();
      expect(tree.count()).assertEqual(3);
    });

    it('updateText_shouldChangeOnlyText', 0, () => {
      const tree: MindTree = buildStandardTree();
      expect(tree.updateText('b', '新B')).assertTrue();
      expect((tree.findById('b') as MindNode).text).assertEqual('新B');
      expect(tree.updateText('none', 'X')).assertFalse();
    });

    it('setCollapsed_shouldStoreState', 0, () => {
      const tree: MindTree = buildStandardTree();
      expect(tree.setCollapsed('a', true)).assertTrue();
      expect((tree.findById('a') as MindNode).collapsed).assertTrue();
      expect(tree.setCollapsed('none', true)).assertFalse();
    });
  });
}
