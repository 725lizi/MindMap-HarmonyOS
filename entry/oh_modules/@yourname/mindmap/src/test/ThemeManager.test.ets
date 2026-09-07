import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { ThemeManager, MindMapTheme } from '../main/ets/theme/MindMapTheme';

export default function themeManagerTest() {
  describe('ThemeManager', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('defaultTheme_shouldHaveCompleteValidValues', 0, () => {
      const theme: MindMapTheme = ThemeManager.defaultTheme();
      expect(theme.rootFillColor.length > 0).assertTrue();
      expect(theme.fontSize > 0).assertTrue();
      expect(theme.rootFontSize > 0).assertTrue();
      expect(theme.cornerRadius >= 0).assertTrue();
      expect(theme.lineWidth > 0).assertTrue();
      expect(theme.lineType).assertEqual('curve');
    });

    it('merge_shouldOverrideProvidedFields', 0, () => {
      const base: MindMapTheme = ThemeManager.defaultTheme();
      const custom: MindMapTheme = ThemeManager.defaultTheme();
      custom.rootFillColor = '#FF0000';
      custom.lineType = 'polyline';
      const merged: MindMapTheme = ThemeManager.merge(base, custom);
      expect(merged.rootFillColor).assertEqual('#FF0000');
      expect(merged.lineType).assertEqual('polyline');
      // 未改字段保持基线
      expect(merged.fontSize).assertEqual(base.fontSize);
    });

    it('merge_invalidNumeric_shouldFallbackToBase', 0, () => {
      const base: MindMapTheme = ThemeManager.defaultTheme();
      const bad: MindMapTheme = ThemeManager.defaultTheme();
      bad.fontSize = 0;
      bad.lineWidth = -1;
      const merged: MindMapTheme = ThemeManager.merge(base, bad);
      expect(merged.fontSize).assertEqual(base.fontSize);
      expect(merged.lineWidth).assertEqual(base.lineWidth);
    });
  });
}
