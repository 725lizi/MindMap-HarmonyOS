import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { MindTree } from '../main/ets/model/MindTree';
import { MindNode } from '../main/ets/model/MindNode';
import {
  EditController,
  MindMapChangeEvent,
  MindMapChangeListener
} from '../main/ets/edit/EditController';

// 记录变更事件的测试监听器（夹具放模块顶层）
class RecordingListener implements MindMapChangeListener {
  events: MindMapChangeEvent[] = [];

  onChange(event: MindMapChangeEvent): void {
    this.events.push(event);
  }

  count(): number {
    return this.events.length;
  }

  lastType(): string {
    return this.events.length === 0 ? '' : this.events[this.events.length - 1].type;
  }
}

function buildTree(): MindTree {
  const tree: MindTree = new MindTree('根', 'r');
  tree.addChildTo('r', new MindNode('a', 'A'));
  tree.addChildTo('a', new MindNode('a1', 'A1'));
  return tree;
}

export default function editControllerTest() {
  describe('EditController', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('init_shouldSelectRoot', 0, () => {
      const editor: EditController = new EditController(buildTree());
      expect(editor.selectedId).assertEqual('r');
      expect((editor.getSelected() as MindNode).id).assertEqual('r');
    });

    it('addChildToSelected_shouldGrowTreeAndSelectNewNode', 0, () => {
      const tree: MindTree = buildTree();
      const editor: EditController = new EditController(tree);
      editor.select('a');
      const created = editor.addChildToSelected('A2');
      expect(created !== null).assertTrue();
      expect(tree.count()).assertEqual(4);
      expect(editor.selectedId).assertEqual((created as MindNode).id);
    });

    it('addSiblingAfterSelected_rootShouldReturnNull', 0, () => {
      const tree: MindTree = buildTree();
      const editor: EditController = new EditController(tree);
      // 根没有兄弟
      expect(editor.addSiblingAfterSelected('根兄弟')).assertNull();
      editor.select('a1');
      const sibling = editor.addSiblingAfterSelected('A2');
      expect(sibling !== null).assertTrue();
      expect(tree.root.children[0].childCount()).assertEqual(2);
    });

    it('removeSelected_rootProtected_shouldReturnFalse', 0, () => {
      const tree: MindTree = buildTree();
      const editor: EditController = new EditController(tree);
      expect(editor.removeSelected()).assertFalse();
      expect(tree.count()).assertEqual(3);
    });

    it('removeSelected_shouldFallbackSelectionToParent', 0, () => {
      const tree: MindTree = buildTree();
      const editor: EditController = new EditController(tree);
      editor.select('a1');
      expect(editor.removeSelected()).assertTrue();
      expect(tree.contains('a1')).assertFalse();
      expect(editor.selectedId).assertEqual('a');
    });

    it('updateSelectedText_shouldChangeText', 0, () => {
      const tree: MindTree = buildTree();
      const editor: EditController = new EditController(tree);
      editor.select('a');
      expect(editor.updateSelectedText('新A')).assertTrue();
      expect((tree.findById('a') as MindNode).text).assertEqual('新A');
    });

    it('listener_shouldReceiveChangeEvents', 0, () => {
      const editor: EditController = new EditController(buildTree());
      const listener: RecordingListener = new RecordingListener();
      editor.addListener(listener);
      editor.select('a');
      expect(listener.lastType()).assertEqual('select');
      editor.addChildToSelected('子');
      expect(listener.lastType()).assertEqual('add');
      expect(listener.count() >= 2).assertTrue();
      editor.removeListener(listener);
      const before: number = listener.count();
      editor.select('r');
      expect(listener.count()).assertEqual(before);
    });

    it('toggleCollapseSelected_shouldFlipState', 0, () => {
      const tree: MindTree = buildTree();
      const editor: EditController = new EditController(tree);
      editor.select('a');
      expect(editor.toggleCollapseSelected()).assertTrue();
      expect((tree.findById('a') as MindNode).collapsed).assertTrue();
      editor.toggleCollapseSelected();
      expect((tree.findById('a') as MindNode).collapsed).assertFalse();
    });
  });
}
