import localUnitTest from './LocalUnit.test';
import mindNodeTest from './MindNode.test';
import mindTreeTest from './MindTree.test';
import layoutEngineTest from './LayoutEngine.test';
import viewportControllerTest from './ViewportController.test';
import jsonSerializerTest from './JsonSerializer.test';
import editControllerTest from './EditController.test';
import themeManagerTest from './ThemeManager.test';

export default function testsuite() {
  localUnitTest();
  mindNodeTest();
  mindTreeTest();
  layoutEngineTest();
  viewportControllerTest();
  jsonSerializerTest();
  editControllerTest();
  themeManagerTest();
}
