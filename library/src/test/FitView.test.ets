import { describe, it, expect } from '@ohos/hypium';
import { computeFitView, FitViewResult } from '../main/ets/gesture/FitView';

const EPS: number = 1e-9;

function assertClose(actual: number, expected: number): void {
  expect(Math.abs(actual - expected) <= EPS).assertTrue();
}

export default function fitViewTest() {
  describe('FitView', () => {
    // 必做用例 (1)：832×182 内容 / 360×640 视口 / padding24 / maxScale1 → 按宽度适配
    it('case01_wideTree_shouldScaleToAvailWidthAndCenter', 0, () => {
      const r: FitViewResult = computeFitView(832, 182, 360, 640);
      assertClose(r.scale, 0.375);
      assertClose(r.offsetX, 24);
      assertClose(r.offsetY, 285.875);
    });

    // 必做用例 (2)：208×92 / 360×640 → 小树不放大，scale 保持 1（maxScale 上限生效），整树居中
    it('case02_smallTree_shouldNotMagnify', 0, () => {
      const r: FitViewResult = computeFitView(208, 92, 360, 640);
      assertClose(r.scale, 1);
      assertClose(r.offsetX, 76);
      assertClose(r.offsetY, 274);
    });

    // 必做用例 (3)：1040×212 / 360×640 → 超宽树仍按可用宽度等比缩小
    it('case03_wideTree_shouldScaleDown', 0, () => {
      const r: FitViewResult = computeFitView(1040, 212, 360, 640);
      assertClose(r.scale, 0.3);
      assertClose(r.offsetX, 24);
      assertClose(r.offsetY, 288.2);
    });

    // 必做用例 (4)：1000×1000 / 360×640 → 宽高均超，取两方向较小比例 0.312
    it('case04_squareContent_shouldUseMinRatio', 0, () => {
      const r: FitViewResult = computeFitView(1000, 1000, 360, 640);
      assertClose(r.scale, 0.312);
      assertClose(r.offsetX, 24);
      assertClose(r.offsetY, 164);
    });

    // 必做用例 (5)：832×182 / 360×640 / padding0 → 无 padding，scale 由视口原值决定
    it('case05_zeroPadding_shouldUseFullViewport', 0, () => {
      const r: FitViewResult = computeFitView(832, 182, 360, 640, 0);
      assertClose(r.scale, 0.4326923076923077);
      assertClose(r.offsetX, 0);
      assertClose(r.offsetY, 280.625);
    });

    // 必做用例 (6)：208×92 / 360×640 / maxScale1.5 → 允许放大到 1.5
    it('case06_raisedMaxScale_shouldAllowMagnify', 0, () => {
      const r: FitViewResult = computeFitView(208, 92, 360, 640, 24, 1.5);
      assertClose(r.scale, 1.5);
      assertClose(r.offsetX, 24);
      assertClose(r.offsetY, 251);
    });

    // 必做用例 (7)：100000×100 / 360×640 → fitMinScale=0.1 兜底，避免缩到看不见
    it('case07_hugeContent_shouldFloorAtFitMinScale', 0, () => {
      const r: FitViewResult = computeFitView(100000, 100, 360, 640);
      assertClose(r.scale, 0.1);
      assertClose(r.offsetX, -4820);
      assertClose(r.offsetY, 315);
    });

    // 必做用例 (8)：四个尺寸分别为 0 的四组零值守卫 → 均返回 {scale:1, offsetX:0, offsetY:0}
    it('case08_zeroDimensionGuard_shouldReturnIdentity', 0, () => {
      const cases: number[][] = [
        [0, 182, 360, 640],   // contentWidth = 0
        [832, 0, 360, 640],   // contentHeight = 0
        [832, 182, 0, 640],   // viewportWidth = 0
        [832, 182, 360, 0]    // viewportHeight = 0
      ];
      for (const c of cases) {
        const r: FitViewResult = computeFitView(c[0], c[1], c[2], c[3]);
        expect(r.scale).assertEqual(1);
        expect(r.offsetX).assertEqual(0);
        expect(r.offsetY).assertEqual(0);
      }
    });

    // 必做用例 (9)：同参数连调两次结果完全相等（确定性）
    it('case09_sameParamsTwice_shouldBeDeterministic', 0, () => {
      const a: FitViewResult = computeFitView(832, 182, 360, 640, 24, 1, 0.1);
      const b: FitViewResult = computeFitView(832, 182, 360, 640, 24, 1, 0.1);
      expect(a.scale).assertEqual(b.scale);
      expect(a.offsetX).assertEqual(b.offsetX);
      expect(a.offsetY).assertEqual(b.offsetY);
    });
  });
}
