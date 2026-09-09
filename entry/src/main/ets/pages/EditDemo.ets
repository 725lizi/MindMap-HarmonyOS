import { router } from '@kit.ArkUI';
import { KeyCode } from '@kit.InputKit';
// focusControl 为 ArkUI 全局命名空间（component/common.d.ts 声明），无需 import
import { MindTree, MindMapView, EditController, MindNode } from 'mindmap-harmony';
import { SampleData } from '../common/SampleData';

/** 示例三：节点编辑——所有修改走 EditController 唯一入口，改完自增 tick 触发重排 */
@Entry
@Component
struct EditDemo {
  // 输入框组件 id，用于回车连录后把焦点抢回来
  private static readonly INPUT_ID: string = 'edit_demo_input';
  private tree: MindTree = SampleData.basicTree();
  private editor: EditController | null = null;
  @State private tick: number = 0;
  @State private selectedText: string = '';
  @State private selectedId: string = '';
  @State private inputText: string = '';

  aboutToAppear(): void {
    this.editor = new EditController(this.tree);
    this.syncSelection();
  }

  private refreshSelected(): void {
    const node: MindNode | null = (this.editor as EditController).getSelected();
    this.selectedText = node === null ? '未选中' : node.text;
  }

  /** 同步选中节点文本与 id（id 驱动 MindMapView 选中描边） */
  private syncSelection(): void {
    this.selectedId = (this.editor as EditController).selectedId;
    this.refreshSelected();
  }

  private bump(): void {
    this.tick++;
    this.syncSelection();
  }

  /**
   * 回车快录：选中普通节点时加同级；根没有兄弟，降级为给根加子级。
   * 输入框为空时使用默认文案；完成后清空并保持焦点，支持连续录入。
   */
  private quickAddByEnter(): void {
    const ed: EditController = this.editor as EditController;
    const current: MindNode | null = ed.getSelected();
    if (current === null) {
      return;
    }
    const isRoot: boolean = current.isRoot();
    const text: string = this.inputText === '' ? (isRoot ? '新子节点' : '新同级') : this.inputText;
    if (isRoot) {
      ed.addChildToSelected(text);
    } else {
      ed.addSiblingAfterSelected(text);
    }
    this.inputText = '';
    this.bump();
    // 状态刷新后把焦点还给输入框，实现「哒哒哒回车连出一串兄弟」
    focusControl.requestFocus(EditDemo.INPUT_ID);
  }

  /** Tab 快加子级（外接键盘） */
  private quickAddChildByTab(): void {
    const ed: EditController = this.editor as EditController;
    const text: string = this.inputText === '' ? '新子节点' : this.inputText;
    ed.addChildToSelected(text);
    this.inputText = '';
    this.bump();
    focusControl.requestFocus(EditDemo.INPUT_ID);
  }

  /** 输入框为空时的快捷键删除：删除选中节点（根受保护），选中态落到父节点 */
  private quickDeleteByKey(): void {
    (this.editor as EditController).removeSelected();
    this.bump();
    focusControl.requestFocus(EditDemo.INPUT_ID);
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

      Text('点选节点后操作：回车=加同级（根上为加子级）｜Tab=加子级｜输入框为空按 Delete=删除｜也可点按钮')
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
        TextInput({ placeholder: '回车加同级 / Tab 加子级；输入文本后点「修改」改名', text: this.inputText })
          .id(EditDemo.INPUT_ID)
          .layoutWeight(1)
          .height(38)
          .onChange((value: string) => {
            this.inputText = value;
          })
          .onSubmit((enterKey: EnterKeyType) => {
            this.quickAddByEnter();
          })
          .onKeyEvent((event: KeyEvent) => {
            // 只处理按下瞬间，避免抬起重复触发
            if (event.type !== KeyType.Down) {
              return;
            }
            if (event.keyCode === KeyCode.KEYCODE_TAB) {
              // Tab 默认会转移焦点，这里拦截冒泡并改为「加子级」
              this.quickAddChildByTab();
              event.stopPropagation();
            } else if ((event.keyCode === KeyCode.KEYCODE_DEL ||
              event.keyCode === KeyCode.KEYCODE_FORWARD_DEL) && this.inputText === '') {
              // 输入框有文字时不拦截，保证正常删字；为空时删除当前选中节点（根受保护）
              this.quickDeleteByKey();
              event.stopPropagation();
            }
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
        selectedId: this.selectedId,
        onNodeSelect: (id: string): void => {
          (this.editor as EditController).select(id);
          this.syncSelection();
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
