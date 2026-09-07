import { router } from '@kit.ArkUI';
import {
  MindTree,
  MindMapView,
  JsonSerializer,
  MindMapSerializeError,
  ImageExporter
} from '@yourname/mindmap';
import { SampleData } from '../common/SampleData';

/** 示例四：JSON 序列化往返 + 组件截图（保存相册在 M4 通过 photoAccessHelper 落地） */
@Entry
@Component
struct ExportDemo {
  private tree: MindTree = SampleData.basicTree();
  @State private tick: number = 0;
  @State private jsonText: string = '';
  @State private importText: string = SampleData.sampleJson();
  @State private message: string = '';

  private doExport(): void {
    this.jsonText = JsonSerializer.serializeTree(this.tree);
    this.message = '已导出 JSON（可直接作为 DeepSeek 输出的标准树节点契约）';
  }

  private doImport(): void {
    try {
      this.tree = JsonSerializer.deserialize(this.importText);
      this.tick++;
      this.message = '导入成功，已重新布局';
    } catch (e) {
      const err = e as MindMapSerializeError;
      this.message = '导入失败：' + (err.code !== undefined ? err.code : '非法数据');
    }
  }

  private async doCapture(): Promise<void> {
    try {
      const pixelMap = await ImageExporter.capture('mindmap_canvas');
      const info = await pixelMap.getImageInfo();
      this.message = '截图成功，尺寸：' + info.size.width.toString() + 'x' + info.size.height.toString() +
        '（保存相册为 M4 任务）';
    } catch (e) {
      this.message = '截图失败：' + JSON.stringify(e);
    }
  }

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
        Text('序列化与导出')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })

      Row({ space: 8 }) {
        Button('导出 JSON').fontSize(13).onClick(() => {
          this.doExport();
        })
        Button('导入 JSON').fontSize(13).onClick(() => {
          this.doImport();
        })
        Button('组件截图').fontSize(13).onClick(() => {
          this.doCapture();
        })
      }
      .width('100%')
      .margin({ bottom: 8 })

      if (this.message !== '') {
        Text(this.message)
          .fontSize(12)
          .fontColor('#059669')
          .width('100%')
          .margin({ bottom: 8 })
      }

      MindMapView({ root: this.tree.root, refreshTick: this.tick })
        .id('mindmap_canvas')
        .height(260)
        .width('100%')
        .backgroundColor(Color.White)
        .borderRadius(12)

      Scroll() {
        Column() {
          if (this.jsonText !== '') {
            Text(this.jsonText)
              .fontSize(11)
              .fontColor('#374151')
              .width('100%')
              .fontFamily('monospace')
          }
        }
        .width('100%')
        .padding(8)
      }
      .layoutWeight(1)
      .width('100%')
      .margin({ top: 8 })
      .backgroundColor(Color.White)
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#F3F4F6')
  }
}
