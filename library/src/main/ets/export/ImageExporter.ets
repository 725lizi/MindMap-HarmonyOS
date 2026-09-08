import { BusinessError } from '@kit.BasicServicesKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { common } from '@kit.AbilityKit';
import type { UIContext } from '@kit.ArkUI';
import image from '@ohos.multimedia.image';

/** 图片导出结果码 */
export enum ImageExportCode {
  SUCCESS = 'SUCCESS',
  CAPTURE_FAILED = 'CAPTURE_FAILED',
  SAVE_FAILED = 'SAVE_FAILED',
  PERMISSION_DENIED = 'PERMISSION_DENIED'
}

export interface ImageExportResult {
  code: ImageExportCode;
  message: string;
}

/**
 * ImageExporter —— 导出图片设备层。
 * 纯逻辑（序列化）在 JsonSerializer；本类只做「组件截图 / 存相册」这类必须依赖系统能力的薄封装，
 * 因此不写离线单测，以一次端到端真机验证收口。
 */
export class ImageExporter {
  /**
   * 组件 UIContext 注册表：组件在 aboutToAppear 绑定、aboutToDisappear 解绑。
   * 截图必须走 UIContext.ComponentSnapshot（全局 componentSnapshot.get 自 API18 弃用），
   * 而静态方法拿不到 UIContext，因此由组件侧注册。
   */
  private static contextRegistry: Map<string, UIContext> = new Map<string, UIContext>();

  /** 绑定组件 id 与其 UIContext（MindMapView 生命周期钩子调用） */
  static bindUIContext(componentId: string, context: UIContext): void {
    ImageExporter.contextRegistry.set(componentId, context);
  }

  /** 解绑组件 id 的 UIContext */
  static unbindUIContext(componentId: string): void {
    ImageExporter.contextRegistry.delete(componentId);
  }

  /**
   * 按组件 id 截取 MindMapView 为 PixelMap。
   * 被截取的组件需要配置 .id(componentId)，并通过 bindUIContext 注册其 UIContext。
   * 对外签名保持 static capture(componentId: string): Promise<image.PixelMap> 不变。
   */
  static capture(componentId: string): Promise<image.PixelMap> {
    return new Promise<image.PixelMap>((resolve, reject) => {
      const uiContext: UIContext | undefined = ImageExporter.contextRegistry.get(componentId);
      if (uiContext === undefined) {
        reject(new Error('CAPTURE_FAILED: UIContext not bound for component "' + componentId + '"'));
        return;
      }
      uiContext.getComponentSnapshot().get(componentId, (err: BusinessError, pixelMap: image.PixelMap) => {
        if (err) {
          reject(err);
          return;
        }
        resolve(pixelMap);
      });
    });
  }

  /**
   * 保存 PixelMap 到系统相册（PNG，文件名 mindmap_时间戳.png）。
   * 调用方需先获得 ohos.permission.WRITE_IMAGEVIDEO 运行时授权；
   * 未授权（错误码 201）返回 PERMISSION_DENIED，其余失败返回 SAVE_FAILED。
   */
  static async saveToGallery(pixelMap: image.PixelMap, context: common.Context): Promise<ImageExportResult> {
    const title: string = 'mindmap_' + Date.now().toString();
    try {
      // PixelMap → PNG ArrayBuffer（内存编码，不落沙箱临时文件）
      const packer: image.ImagePacker = image.createImagePacker();
      let data: ArrayBuffer;
      try {
        data = await packer.packToData(pixelMap, { format: 'image/png', quality: 100 });
      } finally {
        packer.release();
      }

      const helper: photoAccessHelper.PhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
      const request: photoAccessHelper.MediaAssetChangeRequest =
        photoAccessHelper.MediaAssetChangeRequest.createAssetRequest(
          context,
          photoAccessHelper.PhotoType.IMAGE,
          'png',
          { title: title }
        );
      request.addResource(photoAccessHelper.ResourceType.IMAGE_RESOURCE, data);
      await helper.applyChanges(request);

      return {
        code: ImageExportCode.SUCCESS,
        message: '已保存到系统相册：' + title + '.png'
      };
    } catch (e) {
      const err = e as BusinessError;
      if (err.code === 201) {
        return {
          code: ImageExportCode.PERMISSION_DENIED,
          message: '没有相册写入权限，请在系统设置中授权后重试'
        };
      }
      return {
        code: ImageExportCode.SAVE_FAILED,
        message: '保存失败：' + (err.code !== undefined ? err.code.toString() : '未知错误')
      };
    }
  }
}
