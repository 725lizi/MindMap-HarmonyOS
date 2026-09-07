import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { MindTree } from '../main/ets/model/MindTree';
import { MindNode } from '../main/ets/model/MindNode';
import {
  JsonSerializer,
  MindMapSerializeError,
  SerializeErrorCode,
  SerializedDocument
} from '../main/ets/export/JsonSerializer';

function buildSampleTree(): MindTree {
  const tree: MindTree = new MindTree('根', 'r');
  tree.addChildTo('r', new MindNode('a', 'A'));
  tree.addChildTo('r', new MindNode('b', 'B'));
  tree.addChildTo('a', new MindNode('a1', 'A1'));
  return tree;
}

function expectErrorCode(text: string): SerializeErrorCode | null {
  let code: SerializeErrorCode | null = null;
  try {
    JsonSerializer.deserialize(text);
  } catch (e) {
    code = (e as MindMapSerializeError).code;
  }
  return code;
}

export default function jsonSerializerTest() {
  describe('JsonSerializer', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('roundtrip_shouldKeepStructureOrderAndText', 0, () => {
      const tree: MindTree = buildSampleTree();
      const text: string = JsonSerializer.serializeTree(tree, '2026-09-07');
      const restored: MindTree = JsonSerializer.deserialize(text);
      expect(restored.count()).assertEqual(4);
      const beforeIds: string[] = [];
      const afterIds: string[] = [];
      const before: MindNode[] = tree.preorder();
      const after: MindNode[] = restored.preorder();
      for (let i = 0; i < before.length; i++) {
        beforeIds.push(before[i].id);
        afterIds.push(after[i].id);
        expect(after[i].text).assertEqual(before[i].text);
      }
      expect(afterIds.join(',')).assertEqual(beforeIds.join(','));
      // 反向指针重建
      expect((restored.findById('a1') as MindNode).parent !== null).assertTrue();
      expect(restored.depthOf('a1')).assertEqual(2);
    });

    it('serialize_shouldCarryEnvelopeMetadata', 0, () => {
      const text: string = JsonSerializer.serializeTree(buildSampleTree(), '2026-09-07');
      const doc: SerializedDocument = JSON.parse(text) as SerializedDocument;
      expect(doc.format).assertEqual(JsonSerializer.FORMAT);
      expect(doc.version).assertEqual(JsonSerializer.VERSION);
      expect(doc.exportedAt).assertEqual('2026-09-07');
      expect(doc.root.id).assertEqual('r');
    });

    it('deserialize_bareNode_shouldBeAccepted', 0, () => {
      const bare: string = '{"id":"x","text":"裸节点","children":[{"id":"y","text":"子"}]}';
      const tree: MindTree = JsonSerializer.deserialize(bare);
      expect(tree.count()).assertEqual(2);
      expect(tree.root.id).assertEqual('x');
    });

    it('emptyInput_shouldRaiseEmptyInput', 0, () => {
      expect(expectErrorCode('')).assertEqual(SerializeErrorCode.EMPTY_INPUT);
      expect(expectErrorCode('   ')).assertEqual(SerializeErrorCode.EMPTY_INPUT);
    });

    it('invalidJson_shouldRaiseInvalidJson', 0, () => {
      expect(expectErrorCode('{broken json')).assertEqual(SerializeErrorCode.INVALID_JSON);
    });

    it('missingId_shouldRaiseMissingField', 0, () => {
      expect(expectErrorCode('{"text":"没有id"}')).assertEqual(SerializeErrorCode.MISSING_FIELD);
      expect(expectErrorCode('{"id":"","text":"空id"}')).assertEqual(SerializeErrorCode.MISSING_FIELD);
    });

    it('missingText_shouldRaiseMissingField', 0, () => {
      expect(expectErrorCode('{"id":"x"}')).assertEqual(SerializeErrorCode.MISSING_FIELD);
    });

    it('wrongChildrenType_shouldRaiseWrongType', 0, () => {
      expect(expectErrorCode('{"id":"x","text":"X","children":123}')).assertEqual(SerializeErrorCode.WRONG_TYPE);
    });

    it('optionalFields_shouldRestoreWhenPresent', 0, () => {
      const text: string = '{"id":"x","text":"X","collapsed":true,"color":"#FF0000","children":[]}';
      const tree: MindTree = JsonSerializer.deserialize(text);
      expect(tree.root.collapsed).assertTrue();
      expect(tree.root.color).assertEqual('#FF0000');
    });
  });
}
