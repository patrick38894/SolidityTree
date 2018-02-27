contract TreeTest {
  using RedBlack for RBT;
  bool [] results;

  function test1() {
    RBT tree;
    delete results;

    tree.insert(20,20);
    tree.insert(15,15);
    tree.insert(25,25);
    tree.insert(10,10);

    uint nodeP = tree.root;
    results.push(isBlack(nodeP) != 0);

    nodeP = tree.search(15);
    results.push(isBlack(nodeP) != 0);

    nodeP = tree.search(25);
    results.push(isBlack(nodeP) != 0);

    tree.insert(17,17);
    tree.insert(8,8);

    nodeP = tree.search(15);
    results.push(isBlack(nodeP) == 0);

    nodeP = tree.search(10);
    results.push(isBlack(nodeP) != 0);

    nodeP = tree.search(17);
    results.push(isBlack(nodeP) != 0);

    nodeP = tree.search(8);
    results.push(isBlack(nodeP) == 0);

    tree.insert(9,9);

    nodeP = tree.search(10);
    results.push(isBlack(nodeP) == 0);

    nodeP = tree.search(8);
    results.push(isBlack(nodeP) != 0);

    nodeP = tree.search(9);
    results.push(key(left(nodeP)) == 8);

    results.push(tree.testBSTProps);
  }
}
