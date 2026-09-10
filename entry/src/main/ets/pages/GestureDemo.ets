import { router } from '@kit.ArkUI';
import { MindTree, MindMapView } from 'mindmap-harmony';
import { SampleData } from '../common/SampleData';

/** 示例二：手势交互——缩放/平移/双击复位，状态计算在纯逻辑 ViewportController */
@Entry
@Component
struct GestureDemo {
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
        Text('手势交互')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })

      Text('双击放大到 2x（以点击处为中心），再双击回到整树适配；放大后单指拖动平移、不会露出空白边；真机双指捏合缩放（0.5x~3x），模拟器可按 Ctrl+鼠标拖动模拟捏合。')
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
