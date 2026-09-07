import { componentSnapshot } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import image from '@ohos.multimedia.image';

/** 图片导出结果码 */
export enum ImageExportCode {
  SUCCESS = 'SUCCESS',
  NOT_IMPLEMENTED = 'NOT_IMPLEMENTED',
  CAPTURE_FAILED = 'CAPTURE_FAILED'
}

export interface ImageExportResult {
  code: ImageExportCode;
  message: string;
}

/**
 * ImageExporter —— 导出图片设备层（M4 里程碑完整落地，当前为可编译骨架）。
 * 纯逻辑（序列化）在 JsonSerializer；本类只做「组件截图 / 存相册」这类必须依赖系统能力的薄封装，
 * 因此不写离线单测，以一次端到端真机验证收口。
 */
export class ImageExporter {
  /**
   * 按组件 id 截取 MindMapView 为 PixelMap。
   * 被截取的组件需要配置 .id('mindmap_canvas')。
   * TODO(M4): 全局 componentSnapshot.get 自 API18 弃用
   * （useinstead ohos.arkui.UIContext.ComponentSnapshot#get），M4 落地相册导出时一并迁移，
   * 迁移前保持本方法对外签名 static capture(componentId: string): Promise<image.PixelMap> 不变。
   */
  static capture(componentId: string): Promise<image.PixelMap> {
    return new Promise<image.PixelMap>((resolve, reject) => {
      componentSnapshot.get(componentId, (err: BusinessError, pixelMap: image.PixelMap) => {
        if (err) {
          reject(err);
          return;
        }
        resolve(pixelMap);
      });
    });
  }

  /**
   * 保存 PixelMap 到系统相册。
   * TODO(M4): 接入 photoAccessHelper.MediaAssetChangeRequest 完成落盘，
   * 并在 module.json5 声明 ohos.permission.WRITE_IMAGEVIDEO，
   * 覆盖「无权限 / 大图尺寸 / 成功回调」三条路径后做一次真机端到端验证。
   */
  static async saveToGallery(pixelMap: image.PixelMap): Promise<ImageExportResult> {
    // 显式占位：骨架阶段不伪装成已实现，避免 README/简历写了却点不动
    const result: ImageExportResult = {
      code: ImageExportCode.NOT_IMPLEMENTED,
      message: '保存相册将在 M4 里程碑通过 photoAccessHelper 实现'
    };
    return result;
  }
}
