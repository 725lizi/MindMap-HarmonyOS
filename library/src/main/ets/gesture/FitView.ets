/**
 * FitView —— 【整树适配】纯函数（只做初始视图计算，不触碰 UI / 手势 / 状态机）。
 *
 * 布局结束后内容尺寸为 contentWidth×contentHeight，可视区为 viewportWidth×viewportHeight。
 * computeFitView 计算让整棵树完整可见并居中的初始缩放比与平移量：
 *  - 可用区 = 视口 - 2×padding；若该方向减穿（≤0），该方向改用视口原值（视 padding 为 0）；
 *  - raw = min(availWidth/contentWidth, availHeight/contentHeight)，
 *    scale = min(raw, maxScale) 后再取 max(scale, fitMinScale)；
 *  - offset = (viewport - content×scale) / 2（与 ViewportController.clampAxis 居中分支同口径）。
 *
 * 纯函数：不 import 任何 ArkUI / 系统能力，不改入参，同输入必同输出，可离线单测。
 */
export interface FitViewResult {
  scale: number;
  offsetX: number;
  offsetY: number;
}

/**
 * 计算「整树完整可见并居中」的初始缩放比与平移量。
 * @param contentWidth   布局后内容宽度
 * @param contentHeight  布局后内容高度
 * @param viewportWidth  可视区宽度
 * @param viewportHeight 可视区高度
 * @param padding        内容四周保留的空白（两侧各 padding）
 * @param maxScale       缩放上限（默认 1.0：小树不放大）
 * @param fitMinScale    缩放下限兜底（默认 0.1：内容极大时也保证可见一隅）
 */
export function computeFitView(
  contentWidth: number,
  contentHeight: number,
  viewportWidth: number,
  viewportHeight: number,
  padding: number = 24,
  maxScale: number = 1.0,
  fitMinScale: number = 0.1
): FitViewResult {
  // 四个尺寸任一 ≤ 0：尺寸未知/非法，返回恒等（scale=1、原点），不放大不缩小不偏移
  if (contentWidth <= 0 || contentHeight <= 0 || viewportWidth <= 0 || viewportHeight <= 0) {
    return { scale: 1, offsetX: 0, offsetY: 0 };
  }

  // 可用区：视口减去两侧 padding；减完 ≤ 0 该方向视 padding 为 0
  let availWidth: number = viewportWidth - 2 * padding;
  if (availWidth <= 0) {
    availWidth = viewportWidth;
  }
  let availHeight: number = viewportHeight - 2 * padding;
  if (availHeight <= 0) {
    availHeight = viewportHeight;
  }

  // 缩放比：取两方向都能装下的最小者，先封顶 maxScale，再兜底 fitMinScale
  const rawScale: number = Math.min(availWidth / contentWidth, availHeight / contentHeight);
  const scale: number = Math.max(Math.min(rawScale, maxScale), fitMinScale);

  // 平移量：适配后整树在视口内居中
  const offsetX: number = (viewportWidth - contentWidth * scale) / 2;
  const offsetY: number = (viewportHeight - contentHeight * scale) / 2;
  return { scale, offsetX, offsetY };
}
