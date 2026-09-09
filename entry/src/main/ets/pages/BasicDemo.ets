import { router } from '@kit.ArkUI';
import { MindTree, MindMapView } from 'mindmap-harmony';
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

      Text('后序轮廓紧凑布局（tidier）：坐标自动计算、子树不重叠。本页为 G4 不对称树——叶子 B 只与 A 在首层相撞，紧凑收在 A 下方（B 的 y=114，旧全局光标算法为 144；包围盒高 182，旧算法 212）。Canvas 绘制贝塞尔连线。')
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
