/**
 * MindNode —— 思维导图节点数据模型（纯逻辑层，不依赖任何 UI / 系统能力，可离线单测）。
 *
 * 职责边界：只描述「一棵树长什么样」以及父子关系的维护；
 * 不负责坐标计算（layout 层）、不负责绘制（render 层）、不负责 JSON 字符串（export 层）。
 *
 * 对外数据契约：上层（如 FocusTimer + DeepSeek）只需产出同构的标准树节点 JSON：
 * { "id": "n1", "text": "根节点", "children": [ { "id": "n2", "text": "子节点", "children": [] } ] }
 * parent 为运行期反向指针，不参与序列化。
 */
export class MindNode {
  /** 节点唯一标识，全树不可重复（由上层或 MindTree 生成） */
  id: string;
  /** 节点显示文本 */
  text: string;
  /** 子节点有序列表（顺序即渲染顺序） */
  children: MindNode[] = [];
  /** 父节点反向指针；根节点为 null。运行期维护，不参与 JSON 序列化 */
  parent: MindNode | null = null;
  /** 是否折叠子树（V0.1 模型先持有，折叠/展开动画在 V0.2 落地） */
  collapsed: boolean = false;
  /** 节点自定义配色（十六进制色值）；空串表示使用主题默认配色 */
  color: string = '';

  constructor(id: string, text: string) {
    this.id = id;
    this.text = text;
  }

  /** 工厂方法，语义等价于构造函数，便于链式阅读 */
  static create(id: string, text: string): MindNode {
    return new MindNode(id, text);
  }

  /** 是否为叶子节点（没有子节点） */
  isLeaf(): boolean {
    return this.children.length === 0;
  }

  /** 是否为根节点（没有父节点） */
  isRoot(): boolean {
    return this.parent === null;
  }

  /** 直接子节点数量 */
  childCount(): number {
    return this.children.length;
  }

  /**
   * 节点深度：根为 0，每向下一层 +1。
   * 沿 parent 指针向上计数。
   */
  depth(): number {
    let d: number = 0;
    let current: MindNode | null = this.parent;
    while (current !== null) {
      d++;
      current = current.parent;
    }
    return d;
  }

  /** 在直接子节点列表中的下标；不是其子节点返回 -1 */
  indexOfChild(child: MindNode): number {
    for (let i = 0; i < this.children.length; i++) {
      if (this.children[i].id === child.id) {
        return i;
      }
    }
    return -1;
  }

  /**
   * 挂载一个直接子节点（追加到末尾）。
   * - child 若已有父节点，先从旧父节点摘除，保证「一个节点只有一个父亲」；
   * - 拒绝把自己、或自己的祖先挂为子节点，避免成环导致遍历死循环。
   */
  addChild(child: MindNode): void {
    if (child.id === this.id) {
      throw new Error('MindNode.addChild: 不能把节点自身挂为自己的子节点');
    }
    // 成环保护：若 this 出现在 child 的祖先链上，挂上去就会形成环
    let ancestor: MindNode | null = this;
    while (ancestor !== null) {
      if (ancestor.id === child.id) {
        throw new Error('MindNode.addChild: 不能把祖先节点挂为后代，会形成环');
      }
      ancestor = ancestor.parent;
    }
    if (child.parent !== null) {
      child.parent.removeChild(child);
    }
    child.parent = this;
    this.children.push(child);
  }

  /** 在指定下标插入子节点；下标越界时抛错，便于调用方尽早发现 bug */
  insertChildAt(index: number, child: MindNode): void {
    if (index < 0 || index > this.children.length) {
      throw new Error('MindNode.insertChildAt: 下标越界 ' + index);
    }
    if (child.id === this.id) {
      throw new Error('MindNode.insertChildAt: 不能把节点自身挂为自己的子节点');
    }
    if (child.parent !== null) {
      child.parent.removeChild(child);
    }
    child.parent = this;
    this.children.splice(index, 0, child);
  }

  /** 摘除一个直接子节点并解除其 parent 指针；成功返回 true，不是直接子节点返回 false */
  removeChild(child: MindNode): boolean {
    const index: number = this.indexOfChild(child);
    if (index < 0) {
      return false;
    }
    this.children.splice(index, 1);
    child.parent = null;
    return true;
  }
}
