/**
 * ViewportController —— 视口状态机（纯逻辑层，手势识别是 ArkUI 的事，
 * 这里只负责「缩放系数 / 平移量 / 边界钳制」的确定性计算，因此可以离线单测）。
 *
 * 渲染层把 PinchGesture / PanGesture / 双击回调转成 zoomBy / panBy / reset 调用，
 * 自身不持有可变状态，避免「手势状态散落在 UI 回调里」难以测试。
 */
export class ViewportController {
  scale: number = 1;
  offsetX: number = 0;
  offsetY: number = 0;

  private readonly minScale: number;
  private readonly maxScale: number;
  private contentWidth: number = 0;
  private contentHeight: number = 0;
  private viewportWidth: number = 0;
  private viewportHeight: number = 0;

  constructor(minScale: number = 0.5, maxScale: number = 3.0) {
    this.minScale = minScale;
    this.maxScale = maxScale;
  }

  /** 提供布局后的内容尺寸，用于平移钳制 */
  setContentSize(width: number, height: number): void {
    this.contentWidth = width;
    this.contentHeight = height;
    this.clampOffset();
  }

  /** 提供可视画布尺寸，用于平移钳制 */
  setViewportSize(width: number, height: number): void {
    this.viewportWidth = width;
    this.viewportHeight = height;
    this.clampOffset();
  }

  /**
   * 以 (focalX, focalY) 为不动点按 factor 倍缩放（双指捏合逐帧调用）。
   * 保持焦点下的内容点在屏幕上位置不变：newOffset = focal - (focal-oldOffset)*ratio。
   */
  zoomBy(factor: number, focalX: number, focalY: number): void {
    const target: number = this.clampScale(this.scale * factor);
    this.zoomTo(target, focalX, focalY);
  }

  /** 以焦点为不动点直接缩放到指定比例 */
  zoomTo(targetScale: number, focalX: number, focalY: number): void {
    const newScale: number = this.clampScale(targetScale);
    if (newScale === this.scale) {
      return;
    }
    const ratio: number = newScale / this.scale;
    this.offsetX = focalX - (focalX - this.offsetX) * ratio;
    this.offsetY = focalY - (focalY - this.offsetY) * ratio;
    this.scale = newScale;
    this.clampOffset();
  }

  /** 单指平移增量（像素/vp），自动钳制在允许范围内 */
  panBy(dx: number, dy: number): void {
    this.offsetX += dx;
    this.offsetY += dy;
    this.clampOffset();
  }

  /** 双击聚焦 / 复位：回到 1.0 与原点 */
  reset(): void {
    this.scale = 1;
    this.offsetX = 0;
    this.offsetY = 0;
  }

  /** 当前是否处于放大状态（供 UI 决定是否显示「复位」按钮） */
  isZoomed(): boolean {
    return this.scale !== 1 || this.offsetX !== 0 || this.offsetY !== 0;
  }

  private clampScale(value: number): number {
    if (value < this.minScale) {
      return this.minScale;
    }
    if (value > this.maxScale) {
      return this.maxScale;
    }
    return value;
  }

  /**
   * 平移钳制：放大后内容比视口大时，不允许在某一侧露出空白边；
   * 内容比视口小时居中。尺寸未知（初始 0）时不限制，避免误锁。
   */
  private clampOffset(): void {
    this.offsetX = this.clampAxis(this.offsetX, this.contentWidth * this.scale, this.viewportWidth);
    this.offsetY = this.clampAxis(this.offsetY, this.contentHeight * this.scale, this.viewportHeight);
  }

  private clampAxis(offset: number, scaledContent: number, viewport: number): number {
    if (scaledContent <= 0 || viewport <= 0) {
      return offset;
    }
    if (scaledContent <= viewport) {
      // 内容小于视口：居中
      return (viewport - scaledContent) / 2;
    }
    const minOffset: number = viewport - scaledContent;
    if (offset > 0) {
      return 0;
    }
    if (offset < minOffset) {
      return minOffset;
    }
    return offset;
  }
}
