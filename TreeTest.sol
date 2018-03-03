import "RedBlack.sol";

contract TreeTest {
  using RedBlackTree for *;

  function test1() {
    RedBlackTree.Tree tree;

    tree.insert32(20,20);
    tree.insert32(15,15);
    tree.insert32(25,25);
    tree.insert32(10,10);

    uint32 nodeP = tree.root;
    assert(RedBlackTree.isBlack(nodeP) != 0);

    nodeP = tree.root.search(15);
    assert(RedBlackTree.isBlack(nodeP) != 0);

    nodeP = tree.root.search(25);
    assert(RedBlackTree.isBlack(nodeP) != 0);

    tree.insert32(17,17);
    tree.insert32(8,8);

    nodeP = tree.root.search(15);
    assert(RedBlackTree.isBlack(nodeP) == 0);

    nodeP = tree.root.search(10);
    assert(RedBlackTree.isBlack(nodeP) != 0);

    nodeP = tree.root.search(17);
    assert(RedBlackTree.isBlack(nodeP) != 0);

    nodeP = tree.root.search(8);
    assert(RedBlackTree.isBlack(nodeP) == 0);

    tree.insert32(9,9);

    nodeP = tree.root.search(10);
    assert(RedBlackTree.isBlack(nodeP) == 0);

    nodeP = tree.root.search(8);
    assert(RedBlackTree.isBlack(nodeP) != 0);

    nodeP = RedBlackTree.left(tree.root.search(9));
    assert(RedBlackTree.key(nodeP) == 8);

    assert(testBSTProps(tree.root));
  }

  function test2() {
    RedBlackTree.Tree tree;

    tree.insert32(20,20);
    tree.insert32(15,15);
    tree.insert32(25,25);
    tree.insert32(23,23);

    uint32 nodeP = tree.root;
    assert(RedBlackTree.isBlack(nodeP) != 0);
    assert(tree.size == 4);

    tree.remove(15);
    assert(tree.size == 3);

    nodeP = tree.root;
    assert(RedBlackTree.value32(nodeP) == 23);

    assert(testBSTProps(tree.root));
  }

  function test3() {
    RedBlackTree.Tree tree;

    tree.insert32(20,20);
    tree.insert32(15,15);
    tree.insert32(25,25);
    tree.insert32(23,23);
    tree.insert32(27,27);

    uint32 nodeP = tree.root;
    assert(RedBlackTree.isBlack(nodeP) != 0);
    assert(tree.size == 5);

    nodeP = RedBlackTree.right(tree.root);
    assert(RedBlackTree.key(nodeP) == 25);

    nodeP = RedBlackTree.left(RedBlackTree.right(tree.root));
    assert(RedBlackTree.key(nodeP) == 23);
    assert(RedBlackTree.isBlack(nodeP) == 0);

    tree.remove(25);
    assert(tree.size == 4);
   
    nodeP = tree.root;
    assert(RedBlackTree.key(nodeP) == 20);
    
    nodeP = RedBlackTree.right(tree.root);
    assert(RedBlackTree.key(nodeP) == 27);
    assert(RedBlackTree.isBlack(nodeP) != 0);
    
    nodeP = RedBlackTree.right(RedBlackTree.right(tree.root));
    assert(nodeP == 0);
    
    nodeP = RedBlackTree.left(RedBlackTree.right(tree.root));
    assert(RedBlackTree.key(nodeP) == 23);
    assert(RedBlackTree.isBlack(nodeP) == 0);
    
    assert(testBSTProps(tree.root));
  }

  function testBSTProps(uint32 root) returns (bool succ) { 
    succ = true;
    if (root != 0) {
      if (RedBlackTree.left(root) != 0)
        succ = succ && RedBlackTree.key(root) >= RedBlackTree.key(RedBlackTree.left(root));
      if (RedBlackTree.right(root) != 0)
        succ = succ && RedBlackTree.key(root) <= RedBlackTree.key(RedBlackTree.right(root));
      succ = succ && testBSTProps(RedBlackTree.left(root));
      succ = succ && testBSTProps(RedBlackTree.right(root));
    }
  }
}
