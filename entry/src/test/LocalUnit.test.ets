import { describe, it, expect } from '@ohos/hypium';

export default function localUnitTest() {
  describe('EntryLocalSmoke', () => {
    it('assertSmoke', 0, () => {
      expect('mindmap-demo').assertEqual('mindmap-demo');
    });
  });
}
