/**
 * MindMapTheme —— 主题样式模型（纯逻辑）。
 * 配色、圆角、连线类型、字号全部可配置；组件不内置写死颜色，统一从主题读取，
 * 方便接入方适配自己 App 的风格，也便于做「默认主题值 / 自定义覆盖」单测。
 */

/** 连线样式：curve 平滑贝塞尔曲线；polyline 直角折线 */
export type MindMapLineType = 'curve' | 'polyline';

export interface MindMapTheme {
  /** 画布背景色 */
  backgroundColor: string;
  /** 根节点卡片背景色 */
  rootFillColor: string;
  /** 普通节点卡片背景色 */
  nodeFillColor: string;
  /** 选中节点描边色 */
  selectedBorderColor: string;
  /** 节点文字颜色 */
  textColor: string;
  /** 连线颜色 */
  lineColor: string;
  /** 连线宽度（vp） */
  lineWidth: number;
  /** 节点卡片圆角（vp） */
  cornerRadius: number;
  /** 节点字号（fp） */
  fontSize: number;
  /** 根节点字号（fp） */
  rootFontSize: number;
  /** 连线类型 */
  lineType: MindMapLineType;
}

/** 主题工具：默认值与自定义覆盖合并（只覆盖调用方显式传入的字段） */
export class ThemeManager {
  static defaultTheme(): MindMapTheme {
    const theme: MindMapTheme = {
      backgroundColor: '#FFFFFF',
      rootFillColor: '#2563EB',
      nodeFillColor: '#EEF2FF',
      selectedBorderColor: '#F59E0B',
      textColor: '#1F2937',
      lineColor: '#94A3B8',
      lineWidth: 1.5,
      cornerRadius: 10,
      fontSize: 14,
      rootFontSize: 16,
      lineType: 'curve'
    };
    return theme;
  }

  /**
   * 以默认主题为底，用 override 中的非空字段覆盖。
   * ArkTS 不支持 Partial<T> 字面量随意扩散，这里要求调用方传完整主题，
   * 可先取 defaultTheme() 再改其中几个字段，保证任何字段都不为 undefined。
   */
  static merge(base: MindMapTheme, override: MindMapTheme): MindMapTheme {
    const merged: MindMapTheme = {
      backgroundColor: override.backgroundColor !== '' ? override.backgroundColor : base.backgroundColor,
      rootFillColor: override.rootFillColor !== '' ? override.rootFillColor : base.rootFillColor,
      nodeFillColor: override.nodeFillColor !== '' ? override.nodeFillColor : base.nodeFillColor,
      selectedBorderColor: override.selectedBorderColor !== '' ? override.selectedBorderColor : base.selectedBorderColor,
      textColor: override.textColor !== '' ? override.textColor : base.textColor,
      lineColor: override.lineColor !== '' ? override.lineColor : base.lineColor,
      lineWidth: override.lineWidth > 0 ? override.lineWidth : base.lineWidth,
      cornerRadius: override.cornerRadius >= 0 ? override.cornerRadius : base.cornerRadius,
      fontSize: override.fontSize > 0 ? override.fontSize : base.fontSize,
      rootFontSize: override.rootFontSize > 0 ? override.rootFontSize : base.rootFontSize,
      lineType: override.lineType
    };
    return merged;
  }
}
