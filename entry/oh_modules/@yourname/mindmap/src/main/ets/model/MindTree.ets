import { MindNode } from './MindNode';

/**
 * MindTree —— 思维导图整树的操作门面（纯逻辑层）。
 *
 * 对上提供「按 id 增删改查 / 遍历 / 深度 / 父路径」等全部树结构操作，
 * 对下把父子关系维护委托给 MindNode。渲染层、编辑层、序列化层都只跟它打交道，
 * 不自行维护第二份树状态（单一数据源）。
 */
export class MindTree {
  root: MindNode;
  private idCounter: number = 0;
  private readonly idPrefix: string;

  constructor(rootText: string = '中心主题', rootId: string = 'root', idPrefix: string = 'node_') {
    this.root = new MindNode(rootId, rootText);
    this.idPrefix = idPrefix;
  }

  /** 用一个已存在的节点作为根接管一棵树（反序列化时使用） */
  static fromRoot(root: MindNode): MindTree {
    const tree: MindTree = new MindTree(root.text, root.id);
    tree.root = root;
    return tree;
  }

  // ============ 查询 ============

  /** 前序深度优先查找节点；找不到返回 null */
  findById(id: string): MindNode | null {
    const stack: MindNode[] = [this.root];
    while (stack.length > 0) {
      const current: MindNode = stack.pop() as MindNode;
      if (current.id === id) {
        return current;
      }
      // 逆序压栈，保证左侧子节点先被弹出，遍历顺序与 children 顺序一致
      for (let i = current.children.length - 1; i >= 0; i--) {
        stack.push(current.children[i]);
      }
    }
    return null;
  }

  contains(id: string): boolean {
    return this.findById(id) !== null;
  }

  /** 节点深度（根为 0）；不存在返回 -1 */
  depthOf(id: string): number {
    const node: MindNode | null = this.findById(id);
    return node === null ? -1 : node.depth();
  }

  /**
   * 父路径：从根到目标节点的有序节点列表（含两端）。
   * 例如根→A→B，pathToRoot(B) = [root, A, B]；节点不存在返回空数组。
   */
  pathToRoot(id: string): MindNode[] {
    const node: MindNode | null = this.findById(id);
    if (node === null) {
      return [];
    }
    const path: MindNode[] = [];
    let current: MindNode | null = node;
    while (current !== null) {
      path.unshift(current);
      current = current.parent;
    }
    return path;
  }

  /** 父路径的 id 版本，便于上层做高亮/定位 */
  pathIdsToRoot(id: string): string[] {
    const path: MindNode[] = this.pathToRoot(id);
    const ids: string[] = [];
    for (let i = 0; i < path.length; i++) {
      ids.push(path[i].id);
    }
    return ids;
  }

  /** 全树节点总数（含根） */
  count(): number {
    return this.preorder().length;
  }

  /** 前序深度优先遍历（根→子树，按 children 顺序） */
  preorder(): MindNode[] {
    const result: MindNode[] = [];
    const stack: MindNode[] = [this.root];
    while (stack.length > 0) {
      const current: MindNode = stack.pop() as MindNode;
      result.push(current);
      for (let i = current.children.length - 1; i >= 0; i--) {
        stack.push(current.children[i]);
      }
    }
    return result;
  }

  /** 广度优先（按层）遍历 */
  breadthFirst(): MindNode[] {
    const result: MindNode[] = [];
    const queue: MindNode[] = [this.root];
    let head: number = 0;
    while (head < queue.length) {
      const current: MindNode = queue[head];
      head++;
      result.push(current);
      for (let i = 0; i < current.children.length; i++) {
        queue.push(current.children[i]);
      }
    }
    return result;
  }

  /** 全部叶子节点（前序顺序） */
  leaves(): MindNode[] {
    const all: MindNode[] = this.preorder();
    const result: MindNode[] = [];
    for (let i = 0; i < all.length; i++) {
      if (all[i].isLeaf()) {
        result.push(all[i]);
      }
    }
    return result;
  }

  // ============ 增删改 ============

  /** 生成一个带自动 id 的新节点（尚未挂载） */
  createNode(text: string): MindNode {
    this.idCounter++;
    return new MindNode(this.idPrefix + this.idCounter.toString(), text);
  }

  /** 把已有节点挂到 parentId 下（追加末尾）；父节点不存在返回 false */
  addChildTo(parentId: string, child: MindNode): boolean {
    const parent: MindNode | null = this.findById(parentId);
    if (parent === null) {
      return false;
    }
    parent.addChild(child);
    return true;
  }

  /** 在 parentId 下新建一个文本为 text 的子节点并返回；父不存在返回 null */
  appendNewChild(parentId: string, text: string): MindNode | null {
    const parent: MindNode | null = this.findById(parentId);
    if (parent === null) {
      return null;
    }
    const child: MindNode = this.createNode(text);
    parent.addChild(child);
    return child;
  }

  /**
   * 在目标节点后面插入一个同级兄弟节点；目标不存在、或目标是根（根没有兄弟）返回 null。
   * 对应编辑交互：回车快速加同级节点。
   */
  insertSiblingAfter(id: string, text: string): MindNode | null {
    const target: MindNode | null = this.findById(id);
    if (target === null || target.parent === null) {
      return null;
    }
    const parent: MindNode = target.parent;
    const index: number = parent.indexOfChild(target);
    const sibling: MindNode = this.createNode(text);
    parent.insertChildAt(index + 1, sibling);
    return sibling;
  }

  /**
   * 删除节点及其整棵子树。
   * 根节点受保护、不可删除（返回 false）；节点不存在也返回 false。
   */
  remove(id: string): boolean {
    if (id === this.root.id) {
      return false;
    }
    const node: MindNode | null = this.findById(id);
    if (node === null || node.parent === null) {
      return false;
    }
    return node.parent.removeChild(node);
  }

  /** 修改节点文本；节点不存在返回 false */
  updateText(id: string, text: string): boolean {
    const node: MindNode | null = this.findById(id);
    if (node === null) {
      return false;
    }
    node.text = text;
    return true;
  }

  /** 设置折叠状态；节点不存在返回 false */
  setCollapsed(id: string, collapsed: boolean): boolean {
    const node: MindNode | null = this.findById(id);
    if (node === null) {
      return false;
    }
    node.collapsed = collapsed;
    return true;
  }
}
