import { router } from '@kit.ArkUI';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import {
  MindTree,
  MindMapView,
  JsonSerializer,
  MindMapSerializeError,
  ImageExporter,
  ImageExportCode
} from '@yourname/mindmap';
import { SampleData } from '../common/SampleData';

const WRITE_PERMISSION: Permissions = 'ohos.permission.WRITE_IMAGEVIDEO';

/** 示例四：JSON 序列化往返 + 组件截图 + 保存图片到系统相册 */
@Entry
@Component
struct ExportDemo {
  private tree: MindTree = SampleData.basicTree();
  @State private tick: number = 0;
  @State private jsonText: string = '';
  @State private importText: string = SampleData.sampleJson();
  @State private message: string = '';
  // 三态：ok 成功（绿）、fail 失败（红）、warn 拒绝授权（橙）
  @State private messageKind: string = 'ok';

  private doExport(): void {
    this.jsonText = JsonSerializer.serializeTree(this.tree);
    this.showMessage('已导出 JSON（可直接作为 DeepSeek 输出的标准树节点契约）', 'ok');
  }

  private doImport(): void {
    try {
      this.tree = JsonSerializer.deserialize(this.importText);
      this.tick++;
      this.showMessage('导入成功，已重新布局', 'ok');
    } catch (e) {
      const err = e as MindMapSerializeError;
      this.showMessage('导入失败：' + (err.code !== undefined ? err.code : '非法数据'), 'fail');
    }
  }

  private showMessage(text: string, kind: string): void {
    this.message = text;
    this.messageKind = kind;
  }

  private async doCapture(): Promise<void> {
    try {
      const pixelMap = await ImageExporter.capture('mindmap_canvas');
      const info = await pixelMap.getImageInfo();
      this.showMessage('截图成功，尺寸：' + info.size.width.toString() + 'x' + info.size.height.toString(), 'ok');
    } catch (e) {
      this.showMessage('截图失败：' + JSON.stringify(e), 'fail');
    }
  }

  /** 保存前先查权限，未授予则走系统运行时授权弹窗 */
  private async ensureWritePermission(): Promise<boolean> {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const atManager = abilityAccessCtrl.createAtManager();
    const tokenId = context.applicationInfo.accessTokenId;
    const granted: boolean =
      atManager.checkAccessTokenSync(tokenId, WRITE_PERMISSION) === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    if (granted) {
      return true;
    }
    const result = await atManager.requestPermissionsFromUser(context, [WRITE_PERMISSION]);
    return result.authResults.length > 0 && result.authResults[0] === 0;
  }

  private async doSaveToGallery(): Promise<void> {
    const granted = await this.ensureWritePermission();
    if (!granted) {
      this.showMessage('已拒绝相册权限：请在「设置-应用-权限」中开启后重试', 'warn');
      return;
    }
    try {
      const pixelMap = await ImageExporter.capture('mindmap_canvas');
      const context = this.getUIContext().getHostContext() as common.Context;
      const result = await ImageExporter.saveToGallery(pixelMap, context);
      if (result.code === ImageExportCode.SUCCESS) {
        this.showMessage(result.message, 'ok');
      } else if (result.code === ImageExportCode.PERMISSION_DENIED) {
        this.showMessage(result.message, 'warn');
      } else {
        this.showMessage(result.message, 'fail');
      }
    } catch (e) {
      this.showMessage('保存失败：' + JSON.stringify(e), 'fail');
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

      // 2×2 两行布局：小屏竖屏下四个按钮等宽铺满，文字完整不被截断
      Column({ space: 8 }) {
        Row({ space: 8 }) {
          Button('导出 JSON')
            .fontSize(13)
            .layoutWeight(1)
            .onClick(() => {
              this.doExport();
            })
          Button('导入 JSON')
            .fontSize(13)
            .layoutWeight(1)
            .onClick(() => {
              this.doImport();
            })
        }
        .width('100%')

        Row({ space: 8 }) {
          Button('组件截图')
            .fontSize(13)
            .layoutWeight(1)
            .onClick(() => {
              this.doCapture();
            })
          Button('保存到相册')
            .fontSize(13)
            .layoutWeight(1)
            .onClick(() => {
              this.doSaveToGallery();
            })
        }
        .width('100%')
      }
      .width('100%')
      .margin({ bottom: 8 })

      if (this.message !== '') {
        Text(this.message)
          .fontSize(12)
          .fontColor(this.messageKind === 'ok' ? '#059669' :
            (this.messageKind === 'warn' ? '#D97706' : '#DC2626'))
          .width('100%')
          .margin({ bottom: 8 })
      }

      MindMapView({
        root: this.tree.root,
        refreshTick: this.tick,
        snapshotId: 'mindmap_canvas'
      })
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
