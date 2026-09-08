import { MindTree, MindNode } from '@yourname/mindmap';

/** Demo 示例数据：集中构造，四个示例页共用 */
export class SampleData {
  /**
   * G4 轮廓压缩形态示例树：r→[A,B]；A→[a1,a2]；a1→a11；B 为叶子。
   * 紧凑 tidier 布局下 B 会收在 A 的下方（B 的 y=114，旧全局光标算法为 144；
   * 内容包围盒高 182，旧算法为 212），四个示例页共用这棵不对称树以体现紧凑效果。
   */
  static basicTree(): MindTree {
    const tree: MindTree = new MindTree('紧凑布局示例', 'root');
    tree.addChildTo('root', new MindNode('A', '复杂子树 A'));
    tree.addChildTo('root', new MindNode('B', '叶子 B'));
    tree.addChildTo('A', new MindNode('a1', 'a1 深层分支'));
    tree.addChildTo('A', new MindNode('a2', 'a2 子节点'));
    tree.addChildTo('a1', new MindNode('a11', 'a11 更深层'));
    return tree;
  }

  /** 标准 JSON 文本，用于「导入」示例 */
  static sampleJson(): string {
    return '{\n' +
      '  "id": "root",\n' +
      '  "text": "导入的思维导图",\n' +
      '  "children": [\n' +
      '    { "id": "c1", "text": "来自 JSON", "children": [] },\n' +
      '    { "id": "c2", "text": "标准树节点契约", "children": [] }\n' +
      '  ]\n' +
      '}';
  }
}
