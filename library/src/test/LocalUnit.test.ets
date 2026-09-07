import { describe, it, expect } from '@ohos/hypium';

export default function localUnitTest() {
  describe('LocalUnitSmoke', () => {
    it('assertSmoke', 0, () => {
      const a: string = 'mindmap';
      expect(a).assertEqual('mindmap');
    });
  });
}
