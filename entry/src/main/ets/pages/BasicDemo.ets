import { router } from '@kit.ArkUI';
import { MindTree, MindMapView } from '@yourname/mindmap';
import { SampleData } from '../common/SampleData';

/** 示例一：基础渲染——一行接入，数据驱动布局 */
@Entry
@Component
struct BasicDemo {
  private tree: MindTree = SampleData.basicTree();
  @State private tick: number = 0;

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(15)
          .fontColor('#2563EB')
          .onClick(() => {
            // router.back 已 deprecated（本轮保留 router 范式），且可能抛错，需捕获
            try {
              router.back();
            } catch (e) {
              console.error('router.back failed', e);
            }
          })
        Text('基础渲染')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })

      Text('LayoutEngine 自动计算坐标，子树不重叠、同层对齐；Canvas 绘制贝塞尔连线。')
        .fontSize(12)
        .fontColor('#6B7280')
        .width('100%')
        .margin({ bottom: 8 })

      MindMapView({ root: this.tree.root, refreshTick: this.tick })
        .layoutWeight(1)
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#F3F4F6')
  }
}
