library RedBlackTree {

  const uint MAX_HEAP = 0x7FFFFFFF;
  const uint BLACK_MASK = 0x80000000;

  struct MemMap {
    uint32 root;
    uint32 size;
  }

  /*
  // this is the memory layout of the nodes
  struct node {
    uint32 flag|parent;
    uint32 left;
    uint32 right;
    uint32 key;
    uint32 value;
  }
  */

  // memory hacking //

  function parent(uint32 n) returns (uint32) {
    //null checks in the lookup functions allow us to treat
    //null nodes as regular nodes which simplifies some of the
    //logic in the remove functions
    uint32 p;

    if (n != 0) {
      assembly {
        //first bit is reserved for the flag
        p := and(mload(n), not(BLACK_MASK));
      }
    }
    return p;
  }

  function left(uint32 n) returns (uint32) {
    uint32 p;
    if (n != 0) {
      assembly {
        p := mload(add(p, mul(0x01, 0x20)))
      }
    }
    return p;
  }

  function right(uint32 n) returns (uint32) {
    uint32 p;
    if (n != 0) {
      assembly {
        p := mload(add(p, mul(0x02, 0x20)))
      }
    }
    return p;
  }

  function isBlack(uint32 n) returns (uint32) {
    uint32 p;
    if (n != 0) {
      assembly {
        p := and(mload(n), BLACK_MASK);
      }
    }
    return p;
  }

  function key(uint32 n) returns (uint32) {
    uint32 p;
    if (n != 0) {
      assembly {
        p := mload(add(p, mul(0x03, 0x20)))
      }
    }
    return p;
  }

  function value(uint32 n) returns (uint32) {
    uint32 p;
    if (n != 0) {
      assembly {
        p := mload(add(p, mul(0x04, 0x20)))
      }
    }
    return p;
  }


  function writeParent(uint32 n, uint32 p) {
    //no null checks here. dont be stupid
    assembly {
      let b := and(mload(n), BLACK_MASK);
      mstore(n, or(b, p))
    }
  }

  function writeLeft(uint32 n, uint32 l) {
    assembly {
      mstore(add(n, mul(0x01, 0x20)), l)
    }
  }

  function writeRight(uint32 n, uint32 r) {
    assembly {
      mstore(add(n, mul(0x02, 0x20)), r)
    }
  }

  function writeIsBlack(uint32 n, uint32 b) {
    assembly {
      let p := and(mload(n), not(BLACK_MASK));
      mstore(n, or(b, p))
    }
  }

  function writeKey(uint32 n, uint32 k) {
    assembly {
      mstore(add(n, mul(0x03, 0x20)), k)
    }
  }

  function writeValue(uint32 n, uint32 v) {
    assembly {
      mstore(add(n, mul(0x04, 0x20)), v)
    }
  }

  function newNode(uint32 k, uint32 v) internal returns (uint32 n) {
    assembly {
        n := mload(0x40) //load heap pointer
        mstore(add(n, mul(0x03, 0x20)), k)
        mstore(add(n, mul(0x04, 0x20)), v)
        mstore(0x40, add(n, mul(0x05, 0x20))) //inc heap pointer
    }
    require(n < MAX_HEAP - 4); //dont overflow pointers
  }

  function nodeCopy(uint32 d, uint32 s) returns (uint32) {
    for (uint32 i = 0; i < 5; ++i) {
      assembly {
        mstore(add(d,mul(i, 0x20)), mload(add(s, mul(i, 0x20))))
      }
    }
  }

  //utilities
  
  function grandparent(uint32 n) returns (uint32) {
    uint32 p = parent(n);
    return parent(p);
  } 

  function sibling(uint32 n) returns (uint32) {
    uint32 p = parent(n);
    if (p == 0)
      return 0; //no sibling
    if (n == left(p))
      return right(p);
    else
      return left(p);
  }

  function uncle(uint32 n) returns (uint32) {
    uint32 p = parent(n);
    return sibling(p);
  }

  function rotateLeft(uint32 n) returns (uint32) {
    uint32 nnew = right(n);
    nodeCopy(right(n), left(nnew));
    nodeCopy(left(nnew), n);
    nodeCopy(parent(nnew), parent(n));
    nodeCopy(parent(n), nnew);
  }

  function rotateRight(uint32 n) returns (uint32) {
    uint32 nnew = left(n);
    nodeCopy(left(n), right(nnew));
    nodeCopy(right(nnew), n);
    nodeCopy(parent(nnew), parent(n));
    nodeCopy(parent(n), nnew);
  }

  // insert

  function insert(uint32 root, uint32 n) returns (uint32){
    insertRecurse(root, n);
    insertRepairTree(n);
    root = n;
    while (parent(root) != 0)
      root = parent(root);
    return root;
  }

  function insertRecurse(uint32 root, uint32 n) {
    if (root != 0 && key(n) < key(root)) {
      if (left(root) != 0) {
        insertRecurse(left(root), n);
        return;
      }
      else
        nodeCopy(left(root), n);
    }
    else if (root != 0) {
      if (right(root) != 0) {
        insertRecurse(right(root), n);
        return;
      }
      else
        nodeCopy(right(root), n);
    }
    
    //set node props
    writeParent(n, root);
    writeLeft(n, 0);
    writeRight(n, 0);
    writeIsBlack(n, 0);
  }

  function insertRepairTree(uint32 n) {
    if (parent(n) == 0)
      insertCase1(n);
    else if (isBlack(parent(n)) != 0)
      insertCase2(n);
    else if (isBlack(uncle(n)) == 0)
      insertCase3(n);
    else
      insertCase4(n);
  }

  function insertCase1(uint32 n) {
    //n is the root
    if (parent(n) == 0)
      writeIsBlack(n, 1);
  }

  function insertCase2(uint32 n) {
    //parent is black, do nothing
  }

  function insertCase3(uint32 n) {
    //parent and uncle are red
    writeIsBlack(parent(n), 1);
    writeIsBlack(uncle(n), 1);
    writeIsBlack(grandparent(n), 0);
    insertRepairTree(grandparent(n));
  }

  function insertCase4(uint32 n) {
    //parent is red but uncle is black
    uint32 p = parent(n);
    uint32 g = grandparent(n);

    if (n == right(left(g))) {
      rotateLeft(p);
      n = left(n);
    }
    else if (n == left(right(g))) {
      rotateRight(p);
      n = right(n);
    }

    insertCase4step2(n);
  }

  function insertCase4step2(uint32 n) {
    uint32 p = parent(n);
    uint32 g = grandparent(n);
   
    if (n == left(p))
      rotateRight(g);
    else
      rotateLeft(g);
    writeIsBlack(p, 1);
    writeIsBlack(g, 0);
  }

  //remove

  function remove(uint32 n) {
    if (left(n) == 0 && right(n) == 0)
    {
      if (left(parent(n)) == n)
        writeLeft(parent(n), 0);
      else
        writeRight(parent(n), 0);
    }
    else removeOneChild(n);
  }

  function removeOneChild(uint32 n) {
    uint32 child = (right(n) != 0) ? left(n) : right(n);

    writeParent(child, parent(n));
    if (left(parent(n)) == n)
      writeLeft(parent(n), child);
    else
      writeRight(parent(n), child);
    
    if (isBlack(n) != 0) {
      if (isBlack(child) == 0)
        writeIsBlack(child, 1);
      else
        deleteCase1(child);
    }
    //free n would go here if we needed it
  }

  function deleteCase1(uint32 n) {
    //n is the new root
    if (parent(n) != 0)
      deleteCase2(n);
  }

  function deleteCase2(uint32 n) {
    //sibling is red
    uint32 s = sibling(n);

    if (isBlack(s) == 0) {
      writeIsBlack(parent(n), 0);
      writeIsBlack(s, 1);
      if (n == left(parent(n)))
        rotateLeft(parent(n));
      else
        rotateRight(parent(n));
    }
    deleteCase3(n);
  }

  function deleteCase3(uint32 n) {
    //parent, sibling, and siblings children are black
    uint32 s = sibling(n);
    
    if ((isBlack(parent(n)) != 0) &&
        (isBlack(s) != 0) &&
        (isBlack(left(s)) != 0) &&
        (isBlack(right(s)) != 0)) {
      writeIsBlack(s, 0);
      deleteCase1(parent(n));
    }
    else
      deleteCase4(n);
  }

  function deleteCase4(uint32 n) {
    //sibling and siblings childer are black but parent is red
    uint32 s = sibling(n);
 
    if ((isBlack(parent(n)) == 0) &&
        (isBlack(s) != 0) &&
        (isBlack(left(s)) != 0) &&
        (isBlack(right(s)) != 0)) {
      writeIsBlack(s, 0);
      writeIsBlack(parent(n), 0);
    }
    else
      deleteCase5(n);
  }

  function deleteCase5(uint32 n) {
    //sibling is black with one red child which has a black child
    uint32 s = sibling(n);

    if (isBlack(s) != 0) {
      if ((n == left(parent(n))) &&
          (isBlack(right(s)) != 0) &&
          (isBlack(left(s)) == 0)) {
        writeIsBlack(s, 0);
        writeIsBlack(left(s), 0);
        rotateRight(s);
      }
      else if ((n == right(parent(n))) &&
               (isBlack(left(s)) != 0) &&
               (isBlack(right(s)) == 0)) {
        writeIsBlack(s, 0);
        writeIsBlack(right(s), 1);
        rotateLeft(s);
      }
    }
    deleteCase6(n);
  }

  function deleteCase6(uint32 n) {
    //sibling is black, sibling has one red shild
    uint32 s = sibling(n);

    writeIsBlack(s, isBlack(parent(n)));
    writeIsBlack(parent(n), 1);

    if (n == left(parent(n))) {
      writeIsBlack(right(s), 1);
      rotateLeft(parent(n));
    }
    else {
      writeIsBlack(left(s), 1);
      rotateRight(parent(n));
    }
  }
}
