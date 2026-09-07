import { MindNode } from '../model/MindNode';
import { MindTree } from '../model/MindTree';

/** 序列化失败的错误类别，UI 可据此给出「文件损坏 / 格式不符」等不同提示 */
export enum SerializeErrorCode {
  EMPTY_INPUT = 'EMPTY_INPUT',
  INVALID_JSON = 'INVALID_JSON',
  MISSING_FIELD = 'MISSING_FIELD',
  WRONG_TYPE = 'WRONG_TYPE'
}

/** 序列化异常：携带稳定错误码，不依赖字符串匹配 */
export class MindMapSerializeError extends Error {
  code: SerializeErrorCode;

  constructor(code: SerializeErrorCode, message: string) {
    super(message);
    this.code = code;
    this.name = 'MindMapSerializeError';
  }
}

/** 序列化后的纯数据节点（不含 parent 反向指针） */
export interface SerializedNode {
  id: string;
  text: string;
  collapsed: boolean;
  color: string;
  children: SerializedNode[];
}

/** 文档信封：带格式版本，方便未来演进时做兼容迁移 */
export interface SerializedDocument {
  format: string;
  version: number;
  exportedAt: string;
  root: SerializedNode;
}

/** JSON 解析期的宽松原始结构，逐字段做 typeof 校验后才使用 */
interface RawNode {
  id?: Object;
  text?: Object;
  collapsed?: Object;
  color?: Object;
  children?: Object;
}

/**
 * JsonSerializer —— 思维导图 JSON 序列化 / 反序列化（纯逻辑层）。
 * 导出→导入必须往返一致；对非法输入「明确报错而不是崩给用户看」。
 */
export class JsonSerializer {
  static readonly FORMAT: string = 'mindmap-harmonyos';
  static readonly VERSION: number = 1;

  /** 把一棵树序列化为 JSON 字符串；exportedAt 由调用方传入（纯函数不自行取系统时间，便于测试） */
  static serializeTree(tree: MindTree, exportedAt: string = ''): string {
    return JsonSerializer.serializeNode(tree.root, exportedAt);
  }

  static serializeNode(root: MindNode, exportedAt: string = ''): string {
    const plain: SerializedNode = JsonSerializer.toPlain(root);
    const doc: SerializedDocument = {
      format: JsonSerializer.FORMAT,
      version: JsonSerializer.VERSION,
      exportedAt: exportedAt,
      root: plain
    };
    return JSON.stringify(doc, null, 2);
  }

  /** 只导出裸节点（不带文档信封），便于嵌入上层 App 自己的数据结构（如 DeepSeek 返回的 JSON） */
  static toPlain(node: MindNode): SerializedNode {
    const kids: SerializedNode[] = [];
    for (let i = 0; i < node.children.length; i++) {
      kids.push(JsonSerializer.toPlain(node.children[i]));
    }
    const plain: SerializedNode = {
      id: node.id,
      text: node.text,
      collapsed: node.collapsed,
      color: node.color,
      children: kids
    };
    return plain;
  }

  /** 从 JSON 字符串还原一棵 MindTree；非法输入抛 MindMapSerializeError */
  static deserialize(text: string): MindTree {
    if (text === null || text === undefined || text.trim() === '') {
      throw new MindMapSerializeError(SerializeErrorCode.EMPTY_INPUT, '输入为空，无法解析思维导图');
    }
    let parsed: Object;
    try {
      parsed = JSON.parse(text);
    } catch (e) {
      throw new MindMapSerializeError(SerializeErrorCode.INVALID_JSON, '不是合法的 JSON');
    }

    // 兼容两种输入：完整文档信封 { format, version, root } 或裸节点 { id, text, children }
    const envelope = parsed as RawNode;
    let rootRaw: Object;
    if (JsonSerializer.hasEnvelope(parsed)) {
      const doc = parsed as Record<string, Object>;
      const rootField: Object | undefined = doc['root'];
      if (rootField === undefined) {
        throw new MindMapSerializeError(SerializeErrorCode.MISSING_FIELD, '文档缺少 root 字段');
      }
      rootRaw = rootField;
    } else {
      rootRaw = parsed;
    }
    const root: MindNode = JsonSerializer.buildNode(rootRaw);
    return MindTree.fromRoot(root);
  }

  /** 判断是否为带信封的文档（含 format 与 root 字段） */
  private static hasEnvelope(parsed: Object): boolean {
    const record = parsed as Record<string, Object>;
    return record['format'] !== undefined && record['root'] !== undefined;
  }

  /** 递归把宽松原始对象构建为 MindNode，逐字段校验类型 */
  private static buildNode(raw: Object): MindNode {
    if (raw === null || typeof raw !== 'object') {
      throw new MindMapSerializeError(SerializeErrorCode.WRONG_TYPE, '节点必须是对象');
    }
    const obj: RawNode = raw as RawNode;
    if (obj.id === undefined || typeof obj.id !== 'string' || (obj.id as string).length === 0) {
      throw new MindMapSerializeError(SerializeErrorCode.MISSING_FIELD, '节点缺少合法 id（非空字符串）');
    }
    if (obj.text === undefined || typeof obj.text !== 'string') {
      throw new MindMapSerializeError(SerializeErrorCode.MISSING_FIELD, '节点缺少合法 text（字符串）');
    }

    const node: MindNode = new MindNode(obj.id as string, obj.text as string);
    if (obj.collapsed !== undefined) {
      if (typeof obj.collapsed !== 'boolean') {
        throw new MindMapSerializeError(SerializeErrorCode.WRONG_TYPE, 'collapsed 必须是布尔值: ' + (obj.id as string));
      }
      node.collapsed = obj.collapsed as boolean;
    }
    if (obj.color !== undefined) {
      if (typeof obj.color !== 'string') {
        throw new MindMapSerializeError(SerializeErrorCode.WRONG_TYPE, 'color 必须是字符串: ' + (obj.id as string));
      }
      node.color = obj.color as string;
    }
    if (obj.children !== undefined) {
      if (!Array.isArray(obj.children)) {
        throw new MindMapSerializeError(SerializeErrorCode.WRONG_TYPE, 'children 必须是数组: ' + (obj.id as string));
      }
      const list = obj.children as Object[];
      for (let i = 0; i < list.length; i++) {
        const child: MindNode = JsonSerializer.buildNode(list[i]);
        node.addChild(child);
      }
    }
    return node;
  }
}
