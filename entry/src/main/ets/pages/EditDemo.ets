import { router } from '@kit.ArkUI';
import { MindTree, MindMapView, EditController, MindNode } from '@yourname/mindmap';
import { SampleData } from '../common/SampleData';

/** 示例三：节点编辑——所有修改走 EditController 唯一入口，改完自增 tick 触发重排 */
@Entry
@Component
struct EditDemo {
  private tree: MindTree = SampleData.basicTree();
  private editor: EditController | null = null;
  @State private tick: number = 0;
  @State private selectedText: string = '';
  @State private inputText: string = '';

  aboutToAppear(): void {
    this.editor = new EditController(this.tree);
    this.refreshSelected();
  }

  private refreshSelected(): void {
    const node: MindNode | null = (this.editor as EditController).getSelected();
    this.selectedText = node === null ? '未选中' : node.text;
  }

  private bump(): void {
    this.tick++;
    this.refreshSelected();
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
        Text('节点编辑')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ top: 12, bottom: 12 })

      Text('点选节点后：加子级 / 加同级 / 删除（根受保护）/ 修改文本')
        .fontSize(12)
        .fontColor('#6B7280')
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        Text('当前选中：')
          .fontSize(13)
          .fontColor('#374151')
        Text(this.selectedText)
          .fontSize(13)
          .fontColor('#2563EB')
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row({ space: 8 }) {
        Button('加子级').fontSize(13).onClick(() => {
          (this.editor as EditController).addChildToSelected(this.inputText === '' ? '新子节点' : this.inputText);
          this.bump();
        })
        Button('加同级').fontSize(13).onClick(() => {
          (this.editor as EditController).addSiblingAfterSelected(this.inputText === '' ? '新同级' : this.inputText);
          this.bump();
        })
        Button('删除').fontSize(13).fontColor('#DC2626').onClick(() => {
          (this.editor as EditController).removeSelected();
          this.bump();
        })
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row({ space: 8 }) {
        TextInput({ placeholder: '输入文本后点「修改」', text: this.inputText })
          .layoutWeight(1)
          .height(38)
          .onChange((value: string) => {
            this.inputText = value;
          })
        Button('修改').fontSize(13).onClick(() => {
          if (this.inputText !== '') {
            (this.editor as EditController).updateSelectedText(this.inputText);
            this.bump();
          }
        })
      }
      .width('100%')
      .margin({ bottom: 8 })

      MindMapView({
        root: this.tree.root,
        refreshTick: this.tick,
        onNodeSelect: (id: string): void => {
          (this.editor as EditController).select(id);
          this.refreshSelected();
        }
      })
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
