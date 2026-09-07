import { MindTree } from '../model/MindTree';
import { MindNode } from '../model/MindNode';

/** 一次编辑变更的类型，便于 UI 精准刷新、也便于未来做撤销/重做栈 */
export type MindMapChangeType = 'add' | 'remove' | 'update' | 'select' | 'structure';

export interface MindMapChangeEvent {
  type: MindMapChangeType;
  /** 变更涉及的节点 id；整树结构变更可为空串 */
  targetId: string;
}

/** 变更监听者由渲染层实现（ArkUI 组件） */
export interface MindMapChangeListener {
  onChange(event: MindMapChangeEvent): void;
}

/**
 * EditController —— 编辑能力层（纯逻辑）。
 * 统一持有「当前选中节点」并把增删改委托给 MindTree，
 * UI 只派发用户意图（点按钮、回车），不直接改树，保证树只有一个修改入口。
 */
export class EditController {
  private tree: MindTree;
  /** 当前选中节点 id；空串表示未选中 */
  selectedId: string = '';
  private listeners: MindMapChangeListener[] = [];

  constructor(tree: MindTree) {
    this.tree = tree;
    this.selectedId = tree.root.id;
  }

  getTree(): MindTree {
    return this.tree;
  }

  addListener(listener: MindMapChangeListener): void {
    this.listeners.push(listener);
  }

  removeListener(listener: MindMapChangeListener): void {
    const next: MindMapChangeListener[] = [];
    for (let i = 0; i < this.listeners.length; i++) {
      if (this.listeners[i] !== listener) {
        next.push(this.listeners[i]);
      }
    }
    this.listeners = next;
  }

  /** 选中节点 */
  select(id: string): void {
    this.selectedId = id;
    this.emit('select', id);
  }

  getSelected(): MindNode | null {
    if (this.selectedId === '') {
      return null;
    }
    return this.tree.findById(this.selectedId);
  }

  /** 在指定节点下追加子节点，并把选中态切到新节点（对应「加子节点 / Tab」） */
  addChild(parentId: string, text: string): MindNode | null {
    const created: MindNode | null = this.tree.appendNewChild(parentId, text);
    if (created !== null) {
      this.selectedId = created.id;
      this.emit('add', created.id);
    }
    return created;
  }

  /** 在当前选中节点下加子节点 */
  addChildToSelected(text: string): MindNode | null {
    if (this.selectedId === '') {
      return null;
    }
    return this.addChild(this.selectedId, text);
  }

  /** 在当前选中节点后加同级兄弟节点（对应「回车快速加同级」）；根没有兄弟 */
  addSiblingAfterSelected(text: string): MindNode | null {
    if (this.selectedId === '') {
      return null;
    }
    const created: MindNode | null = this.tree.insertSiblingAfter(this.selectedId, text);
    if (created !== null) {
      this.selectedId = created.id;
      this.emit('add', created.id);
    }
    return created;
  }

  /**
   * 删除当前选中节点及其子树。
   * 根节点受保护返回 false；删除成功后选中态落到被删节点的父节点。
   */
  removeSelected(): boolean {
    if (this.selectedId === '' || this.selectedId === this.tree.root.id) {
      return false;
    }
    const target: MindNode | null = this.tree.findById(this.selectedId);
    if (target === null || target.parent === null) {
      return false;
    }
    const parentId: string = target.parent.id;
    const removedId: string = this.selectedId;
    const ok: boolean = this.tree.remove(removedId);
    if (ok) {
      this.selectedId = parentId;
      this.emit('remove', removedId);
    }
    return ok;
  }

  /** 修改当前选中节点文本 */
  updateSelectedText(text: string): boolean {
    if (this.selectedId === '') {
      return false;
    }
    const ok: boolean = this.tree.updateText(this.selectedId, text);
    if (ok) {
      this.emit('update', this.selectedId);
    }
    return ok;
  }

  /** 折叠/展开当前选中节点的子树（V0.1 模型层已支持，动画 V0.2） */
  toggleCollapseSelected(): boolean {
    if (this.selectedId === '') {
      return false;
    }
    const node: MindNode | null = this.tree.findById(this.selectedId);
    if (node === null) {
      return false;
    }
    const ok: boolean = this.tree.setCollapsed(this.selectedId, !node.collapsed);
    if (ok) {
      this.emit('structure', this.selectedId);
    }
    return ok;
  }

  private emit(type: MindMapChangeType, targetId: string): void {
    const event: MindMapChangeEvent = { type: type, targetId: targetId };
    for (let i = 0; i < this.listeners.length; i++) {
      this.listeners[i].onChange(event);
    }
  }
}
