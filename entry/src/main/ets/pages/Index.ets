import { router } from '@kit.ArkUI';

interface DemoEntry {
  title: string;
  desc: string;
  url: string;
}

@Component
struct DemoRow {
  entry: DemoEntry = { title: '', desc: '', url: '' };
  onTap: (url: string) => void = (url: string): void => {};

  build() {
    Row() {
      Column() {
        Text(this.entry.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor('#111827')
        Text(this.entry.desc)
          .fontSize(13)
          .fontColor('#6B7280')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('>')
        .fontSize(18)
        .fontColor('#9CA3AF')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .onClick(() => {
      this.onTap(this.entry.url);
    })
  }
}

@Entry
@Component
struct Index {
  private demos: DemoEntry[] = [
    { title: '基础渲染', desc: '传入标准树节点 JSON，自动布局并渲染节点与连线', url: 'pages/BasicDemo' },
    { title: '手势交互', desc: '双指缩放、单指平移、双击复位', url: 'pages/GestureDemo' },
    { title: '节点编辑', desc: '选中节点，增删改 / 加同级 / 加子级', url: 'pages/EditDemo' },
    { title: '序列化与导出', desc: 'JSON 导出导入往返、组件截图（M4 存相册）', url: 'pages/ExportDemo' }
  ];

  private gotoPage(url: string): void {
    router.pushUrl({ url: url });
  }

  build() {
    Column() {
      Text('MindMap-HarmonyOS Demo')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#111827')
        .width('100%')
        .margin({ bottom: 4 })
      Text('@yourname/mindmap · 鸿蒙原生思维导图组件')
        .fontSize(13)
        .fontColor('#6B7280')
        .width('100%')
        .margin({ bottom: 16 })

      Column({ space: 10 }) {
        ForEach(this.demos, (item: DemoEntry) => {
          DemoRow({ entry: item, onTap: (url: string): void => this.gotoPage(url) })
        }, (item: DemoEntry): string => item.url)
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .backgroundColor('#F3F4F6')
    .alignItems(HorizontalAlign.Start)
  }
}
