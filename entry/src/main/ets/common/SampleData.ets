import { MindTree, MindNode } from '@yourname/mindmap';

/** Demo 示例数据：集中构造，四个示例页共用 */
export class SampleData {
  /** 一棵三层示例树 */
  static basicTree(): MindTree {
    const tree: MindTree = new MindTree('鸿蒙学习路线', 'root');
    tree.addChildTo('root', new MindNode('ui', 'ArkUI 界面'));
    tree.addChildTo('root', new MindNode('model', '数据模型'));
    tree.addChildTo('root', new MindNode('test', '单元测试'));
    tree.addChildTo('ui', new MindNode('ui-1', '声明式 UI'));
    tree.addChildTo('ui', new MindNode('ui-2', '组件化'));
    tree.addChildTo('model', new MindNode('model-1', 'MindNode'));
    tree.addChildTo('model', new MindNode('model-2', 'MindTree'));
    tree.addChildTo('test', new MindNode('test-1', 'Hypium'));
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
