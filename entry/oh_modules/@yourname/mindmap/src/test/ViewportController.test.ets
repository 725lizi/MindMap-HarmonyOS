import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { ViewportController } from '../main/ets/gesture/ViewportController';

export default function viewportControllerTest() {
  describe('ViewportController', () => {
    beforeAll(() => {});
    beforeEach(() => {});
    afterEach(() => {});
    afterAll(() => {});

    it('init_shouldDefaultToIdentity', 0, () => {
      const vp: ViewportController = new ViewportController();
      expect(vp.scale).assertEqual(1);
      expect(vp.offsetX).assertEqual(0);
      expect(vp.offsetY).assertEqual(0);
      expect(vp.isZoomed()).assertFalse();
    });

    it('zoomTo_shouldClampToMinMax', 0, () => {
      const vp: ViewportController = new ViewportController(0.5, 3.0);
      vp.zoomTo(100, 0, 0);
      expect(vp.scale).assertEqual(3.0);
      vp.zoomTo(0.01, 0, 0);
      expect(vp.scale).assertEqual(0.5);
    });

    it('zoomBy_shouldMultiplyScale', 0, () => {
      const vp: ViewportController = new ViewportController();
      vp.zoomBy(2, 0, 0);
      expect(vp.scale).assertEqual(2);
      vp.zoomBy(1.5, 0, 0);
      expect(vp.scale).assertEqual(3);
    });

    it('zoomAtFocal_shouldKeepFocalContentPointFixed', 0, () => {
      const vp: ViewportController = new ViewportController();
      vp.setContentSize(1000, 1000);
      vp.setViewportSize(300, 300);
      const focalX: number = 120;
      // 缩放前焦点对应的内容坐标
      const contentBefore: number = (focalX - vp.offsetX) / vp.scale;
      vp.zoomTo(2, focalX, 0);
      const contentAfter: number = (focalX - vp.offsetX) / vp.scale;
      // 以焦点为中心缩放后，焦点下的内容点不应漂移
      expect(Math.abs(contentAfter - contentBefore) < 1e-9).assertTrue();
    });

    it('panBy_shouldAccumulateDelta', 0, () => {
      const vp: ViewportController = new ViewportController();
      vp.setContentSize(2000, 2000);
      vp.setViewportSize(300, 300);
      vp.panBy(-30, -20);
      expect(vp.offsetX).assertEqual(-30);
      expect(vp.offsetY).assertEqual(-20);
      vp.panBy(-10, 5);
      expect(vp.offsetX).assertEqual(-40);
      expect(vp.offsetY).assertEqual(-15);
    });

    it('pan_shouldClampWithoutBlankEdge', 0, () => {
      const vp: ViewportController = new ViewportController();
      // 放大后内容 400，视口 100，允许 offset 区间 [-300, 0]
      vp.setContentSize(400, 400);
      vp.setViewportSize(100, 100);
      vp.zoomTo(1, 0, 0); // scale=1 时内容=视口，offset 锁 0
      vp.panBy(80, 0);
      expect(vp.offsetX).assertEqual(0);
      vp.zoomTo(2, 0, 0);
      vp.panBy(-5000, 0);
      // scale=2 时内容 800、视口 100，下界 = 100-800 = -700
      expect(vp.offsetX).assertEqual(-700);
    });

    it('smallContent_shouldBeCentered', 0, () => {
      const vp: ViewportController = new ViewportController();
      vp.setContentSize(50, 50);
      vp.setViewportSize(100, 100);
      // 内容小于视口时水平/垂直居中：(100-50)/2 = 25
      expect(vp.offsetX).assertEqual(25);
      expect(vp.offsetY).assertEqual(25);
    });

    it('reset_shouldRestoreIdentity', 0, () => {
      const vp: ViewportController = new ViewportController();
      vp.setContentSize(2000, 2000);
      vp.setViewportSize(300, 300);
      vp.zoomBy(2, 0, 0);
      vp.panBy(-40, -40);
      expect(vp.isZoomed()).assertTrue();
      vp.reset();
      expect(vp.scale).assertEqual(1);
      expect(vp.offsetX).assertEqual(0);
      expect(vp.offsetY).assertEqual(0);
    });
  });
}
