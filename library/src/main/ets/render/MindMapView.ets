import { MindNode } from '../model/MindNode';
import { LayoutEngine } from '../layout/LayoutEngine';
import { LayoutNode, Edge, LayoutResult, LayoutConfig } from '../layout/LayoutTypes';
import { ViewportController } from '../gesture/ViewportController';
import { MindMapTheme, ThemeManager } from '../theme/MindMapTheme';

/**
 * MindMapView —— 思维导图渲染组件（render 层）。
 * 职责：吃一棵 MindNode 树 + 主题，内部用 LayoutEngine 算坐标，
 * 用 Canvas 画连线、用定位卡片画节点，并把双指缩放/单指平移/双击复位
 * 全部委托给纯逻辑 ViewportController。
 *
 * 数据驱动、无需手摆坐标。编辑后请把 refreshTick 自增以触发重新布局；
 * 节点点击通过 onNodeSelect 回调上抛，组件内部不修改树（单向数据流）。
 *
 * 最简用法：
 *   MindMapView({ root: this.tree.root, refreshTick: this.tick })
 */
@Component
export struct MindMapView {
  /** 树根节点（标准树结构，组件只读不改） */
  @Prop root: MindNode = new MindNode('root', '中心主题');
  /** 编辑后自增，触发重新布局与重绘 */
  @Prop @Watch('onRefreshTickChanged') refreshTick: number = 0;
  /** 可选自定义布局参数 */
  layoutConfig: LayoutConfig | null = null;
  /** 主题，默认走 ThemeManager.defaultTheme() */
  theme: MindMapTheme = ThemeManager.defaultTheme();
  /** 节点点击回调（上抛选中意图） */
  onNodeSelect: (id: string) => void = (id: string): void => {};
  // 导出图片截图时由使用方挂 .id('mindmap_canvas')，再交给 ImageExporter.capture

  @State private layoutNodes: LayoutNode[] = [];
  @State private edges: Edge[] = [];
  @State private contentWidth: number = 0;
  @State private contentHeight: number = 0;
  // 视口状态镜像：ViewportController 是纯逻辑状态机，@State 镜像负责驱动界面刷新
  @State private scaleValue: number = 1;
  @State private translateX: number = 0;
  @State private translateY: number = 0;

  private engine: LayoutEngine = new LayoutEngine();
  private viewport: ViewportController = new ViewportController();
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private canvasReady: boolean = false;
  private viewportWidth: number = 0;
  private viewportHeight: number = 0;
  private lastPanX: number = 0;
  private lastPanY: number = 0;
  private gestureStartScale: number = 1;

  aboutToAppear(): void {
    this.relayout();
  }

  /** refreshTick 变化（编辑后）时重新布局 */
  onRefreshTickChanged(): void {
    this.relayout();
  }

  private relayout(): void {
    const result: LayoutResult = this.layoutConfig === null
      ? this.engine.layout(this.root)
      : this.engine.layout(this.root, this.layoutConfig);
    this.layoutNodes = result.nodes;
    this.edges = result.edges;
    this.contentWidth = result.contentWidth;
    this.contentHeight = result.contentHeight;
    this.viewport.setContentSize(result.contentWidth, result.contentHeight);
    this.syncViewport();
    // Canvas 若已就绪立即重绘；未就绪则等 onReady
    if (this.canvasReady) {
      this.drawEdges();
    }
  }

  private syncViewport(): void {
    this.scaleValue = this.viewport.scale;
    this.translateX = this.viewport.offsetX;
    this.translateY = this.viewport.offsetY;
  }

  /** 在 Canvas 上绘制父子连线（坐标与节点卡片同属布局坐标系，整体一起缩放平移） */
  private drawEdges(): void {
    const ctx: CanvasRenderingContext2D = this.canvasContext;
    ctx.clearRect(0, 0, this.contentWidth, this.contentHeight);
    ctx.strokeStyle = this.theme.lineColor;
    ctx.lineWidth = this.theme.lineWidth;
    for (let i = 0; i < this.edges.length; i++) {
      const edge: Edge = this.edges[i];
      ctx.beginPath();
      ctx.moveTo(edge.fromX, edge.fromY);
      if (this.theme.lineType === 'polyline') {
        const midX: number = (edge.fromX + edge.toX) / 2;
        ctx.lineTo(midX, edge.fromY);
        ctx.lineTo(midX, edge.toY);
        ctx.lineTo(edge.toX, edge.toY);
      } else {
        const midX: number = (edge.fromX + edge.toX) / 2;
        ctx.bezierCurveTo(midX, edge.fromY, midX, edge.toY, edge.toX, edge.toY);
      }
      ctx.stroke();
    }
  }

  private textOf(id: string): string {
    const stack: MindNode[] = [this.root];
    while (stack.length > 0) {
      const current: MindNode = stack.pop() as MindNode;
      if (current.id === id) {
        return current.text;
      }
      for (let i = current.children.length - 1; i >= 0; i--) {
        stack.push(current.children[i]);
      }
    }
    return '';
  }

  private isRoot(id: string): boolean {
    return id === this.root.id;
  }

  private fillColorOf(id: string): string {
    return this.isRoot(id) ? this.theme.rootFillColor : this.theme.nodeFillColor;
  }

  private fontColorOf(id: string): string {
    return this.isRoot(id) ? '#FFFFFF' : this.theme.textColor;
  }

  private onPinchStart(): void {
    // PinchGesture 的 event.scale 相对本次手势起点（起点=1），记录手势开始时的绝对倍率
    this.gestureStartScale = this.viewport.scale;
  }

  private applyPinch(event: PinchGestureEvent): void {
    const target: number = this.gestureStartScale * event.scale;
    this.viewport.zoomTo(target, event.pinchCenterX, event.pinchCenterY);
    this.syncViewport();
  }

  private applyPanStart(): void {
    this.lastPanX = 0;
    this.lastPanY = 0;
  }

  private applyPanUpdate(event: GestureEvent): void {
    const dx: number = event.offsetX - this.lastPanX;
    const dy: number = event.offsetY - this.lastPanY;
    this.lastPanX = event.offsetX;
    this.lastPanY = event.offsetY;
    this.viewport.panBy(dx, dy);
    this.syncViewport();
  }

  private applyDoubleTap(): void {
    this.viewport.reset();
    this.syncViewport();
  }

  build() {
    Stack() {
      // 连线层：尺寸覆盖整个布局内容区
      Canvas(this.canvasContext)
        .width(this.contentWidth)
        .height(this.contentHeight)
        .onReady(() => {
          this.canvasReady = true;
          this.drawEdges();
        })

      // 节点层：按布局坐标定位
      ForEach(this.layoutNodes, (item: LayoutNode) => {
        Stack() {
          Text(this.textOf(item.id))
            .fontSize(this.isRoot(item.id) ? this.theme.rootFontSize : this.theme.fontSize)
            .fontColor(this.fontColorOf(item.id))
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
            .width(item.width - 16)
        }
        .width(item.width)
        .height(item.height)
        .position({ x: item.x, y: item.y })
        .backgroundColor(this.fillColorOf(item.id))
        .borderRadius(this.theme.cornerRadius)
        .border({ width: 1, color: '#CBD5E1' })
        .onClick(() => {
          this.onNodeSelect(item.id);
        })
      }, (item: LayoutNode): string => item.id + '_' + this.refreshTick.toString())
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.backgroundColor)
    .clip(true)
    .scale({ x: this.scaleValue, y: this.scaleValue, centerX: 0, centerY: 0 })
    .translate({ x: this.translateX, y: this.translateY })
    .onAreaChange((oldValue: Area, newValue: Area) => {
      this.viewportWidth = newValue.width as number;
      this.viewportHeight = newValue.height as number;
      this.viewport.setViewportSize(this.viewportWidth, this.viewportHeight);
      this.syncViewport();
    })
    .gesture(
      GestureGroup(GestureMode.Parallel,
        PinchGesture({ fingers: 2, distance: 1 })
          .onActionStart(() => {
            this.onPinchStart();
          })
          .onActionUpdate((event: PinchGestureEvent) => {
            this.applyPinch(event);
          }),
        PanGesture({ fingers: 1 })
          .onActionStart(() => {
            this.applyPanStart();
          })
          .onActionUpdate((event: GestureEvent) => {
            this.applyPanUpdate(event);
          }),
        TapGesture({ count: 2 })
          .onAction(() => {
            this.applyDoubleTap();
          })
      )
    )
  }
}
