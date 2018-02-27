library RedBlack {

  struct node {
    uint parent;
    uint left;
    uint right;
    uint isBlack;
    uint key;
    uint value;
  }

  // memory hacking //

  function parent(uint n) returns (uint) {
    uint p;
    assembly {
      p := mload(n)
    }
    return p;
  }

  function left(uint n) returns (uint) {
    uint p;
    assembly {
      p := mload(add(p, mul(0x01, 0x20)))
    }
    return p;
  }

  function right(uint n) returns (uint) {
    uint p;
    assembly {
      p := mload(add(p, mul(0x02, 0x20)))
    }
    return p;
  }

  function isBlack(uint n) returns (uint) {
    uint p;
    assembly {
      p := mload(add(p, mul(0x03, 0x20)))
    }
    return p;
  }

  function key(uint n) returns (uint) {
    uint p;
    assembly {
      p := mload(add(p, mul(0x04, 0x20)))
    }
    return p;
  }

  function value(uint n) returns (uint) {
    uint p;
    assembly {
      p := mload(add(p, mul(0x05, 0x20)))
    }
    return p;
  }


  function writeParent(uint n, uint p) {
    assembly {
      mstore(n, p)
    }
  }

  function writeLeft(uint n, uint l) {
    assembly {
      mstore(add(n, mul(0x01, 0x20)), l)
    }
  }

  function writeRight(uint n, uint r) {
    assembly {
      mstore(add(n, mul(0x02, 0x20)), r)
    }
  }

  function writeIsBlack(uint n, uint b) {
    assembly {
      mstore(add(n, mul(0x03, 0x20)), b)
    }
  }

  function writeKey(uint n, uint d) {
    assembly {
      mstore(add(n, mul(0x04, 0x20)), d)
    }
  }

  function writeValue(uint n, uint d) {
    assembly {
      mstore(add(n, mul(0x05, 0x20)), d)
    }
  }

  function writeNode(uint d, node memory n) internal {
    for (uint i = 0; i < 6; ++i) {
      assembly {
        mstore(add(d, mul(i, 0x20)), mload(add(n, mul(i, 0x20))))
      }
    }
  }

  function nodeCopy(uint d, uint s) returns (uint) {
    for (uint i = 0; i < 6; ++i) {
      assembly {
        mstore(add(d,mul(i, 0x20)), mload(add(s, mul(i, 0x20))))
      }
    }
  }

  //utilities
  
  function grandparent(uint n) returns (uint) {
    uint p = parent(n);
    if (p == 0)
      return 0; //means no grandparent
    else
      return parent(p);
  } 

  function sibling(uint n) returns (uint) {
    uint p = parent(n);
    if (p == 0)
      return 0; //no sibling
    if (n == left(p))
      return right(p);
    else
      return left(p);
  }

  function uncle(uint n) returns (uint) {
    uint p = parent(n);
    if (p == 0)
      return 0;
    return sibling(p);
  }

  function rotateLeft(uint n) returns (uint) {
    uint nnew = right(n);
    nodeCopy(right(n), left(nnew));
    nodeCopy(left(nnew), n);
    nodeCopy(parent(nnew), parent(n));
    nodeCopy(parent(n), nnew);
  }

  function rotateRight(uint n) returns (uint) {
    uint nnew = left(n);
    nodeCopy(left(n), right(nnew));
    nodeCopy(right(nnew), n);
    nodeCopy(parent(nnew), parent(n));
    nodeCopy(parent(n), nnew);
  }

  // insert

  function insert(uint root, uint n) returns (uint){
    insertRecurse(root, n);
    insertRepairTree(n);
    root = n;
    while (parent(root) != 0)
      root = parent(root);
    return root;
  }

  function insertRecurse(uint root, uint n) {
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

  function insertRepairTree(uint n) {
    if (parent(n) == 0)
      insertCase1(n);
    else if (isBlack(parent(n)) != 0)
      return; //insertCase2 does nothing
    else if (isBlack(uncle(n)) == 0)
      insertCase3(n);
    else
      insertCase4(n);
  }

  function insertCase1(uint n) {
    if (parent(n) == 0)
      writeIsBlack(n, 1);
  }

  function insertCase3(uint n) {
    writeIsBlack(parent(n), 1);
    writeIsBlack(uncle(n), 1);
    writeIsBlack(grandparent(n), 0);
    insertRepairTree(grandparent(n));
  }

  function insertCase4(uint n) {
    uint p = parent(n);
    uint g = grandparent(n);

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

  function insertCase4step2(uint n) {
    uint p = parent(n);
    uint g = grandparent(n);
   
    if (n == left(p))
      rotateRight(g);
    else
      rotateLeft(g);
    writeIsBlack(p, 1);
    writeIsBlack(g, 0);
  }

  //remove

  function remove(uint n) {
    if (left(n) == 0 && right(n) == 0)
    {
      if (left(parent(n)) == n)
        writeLeft(parent(n), 0);
      else
        writeRight(parent(n), 0);
    }
    else removeOneChild(n);
  }

  function removeOneChild(uint n) {
    uint child = (right(n) != 0) ? left(n) : right(n);

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

  function deleteCase1(uint n) {
    if (parent(n) != 0)
      deleteCase2(n);
  }

  //note if left/right(NULL) returns 0 these will work.
  //this means we need to reserve memory[NULL] to memory[NULL+5] to be 0's
  //and possibly replace instances of '0' with 'NULL'
  //maybe NULL = uint256(-5) ?

  function deleteCase2(uint n) {
    uint s = sibling(n);

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

  function deleteCase3(uint n) {
    uint s = sibling(n);
    
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

  function deleteCase4(uint n) {
    uint s = sibling(n);
 
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

  function deleteCase5(uint n) {
    uint s = sibling(n);

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

  function deleteCase6(uint n) {
    uint s = sibling(n);

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
