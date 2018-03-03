pragma solidity ^0.4.18;

library RedBlackTree {

  struct Tree {
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

  function parent(uint32 n) internal pure returns (uint32 p) {
    //null checks in the lookup functions allow us to treat
    //null nodes as regular nodes which simplifies some of the
    //logic in the remove functions

    uint mask = 0x7FFFFFFF;
    if (n != 0) {
      assembly {
        //first bit is reserved for the flag
        p := and(mload(n), mask)
      }
    }
  }

  function left(uint32 n) internal pure returns (uint32) {
    uint l;
    uint mask = 0xFFFFFFFF << 32;
    if (n != 0) {
      assembly {
        l := and(mload(n), mask)
      }
    }
    return uint32(l >> 32);
  }

  function right(uint32 n) internal pure returns (uint32) {
    uint r;
    uint mask = 0xFFFFFFFF << 64;
    if (n != 0) {
      assembly {
        r := mload(and(n, mask))
      }
    }
    return uint32(r >> 64);
  }

  function isBlack(uint32 n) internal pure returns (uint32) {
    uint b;
    uint mask = 0x80000000;
    if (n != 0) {
      assembly {
        b := and(mload(n), mask)
      }
    }
    return uint32(b >> 31);
  }

  function key(uint32 n) internal pure returns (uint32) {
    uint k;
    uint mask = 0xFFFFFFFF << 96;
    if (n != 0) {
      assembly {
        k := mload(and(n, mask))
      }
    }
    return uint32(k >> 96);
  }

  function value32(uint32 n) internal pure returns (uint32) {
    //optional: define other valueN functions up to value128
    uint v;
    uint mask = uint(-1) << 128;
    if (n != 0) {
      assembly {
        v := mload(and(n, mask))
      }
    }
    return uint32(v >> 128);
  }

  function value128(uint32 n) internal pure returns (uint128) {
    //optional: define other valueN functions up to value128
    uint v;
    uint mask = uint(-1) << 128;
    if (n != 0) {
      assembly {
        v := mload(and(n, mask))
      }
    }
    return uint128(v >> 128);
  }

  function writeParent(uint32 n, uint32 p) internal pure {
    //no null checks here. dont be stupid
    uint mask = uint(-1) ^ 0x7FFFFFFF;
    assembly {
      mstore(n, or(p, and(mload(n), mask)))
    }
  }

  function writeLeft(uint32 n, uint32 l) internal pure {
    uint mask = uint(-1) ^ (0xFFFFFFFF << 32);
    uint shifted = uint(l) << 32;
    assembly {
      mstore(n, or(shifted,
          and(mload(n), mask)))
    }
  }

  function writeRight(uint32 n, uint32 r) internal pure {
    uint mask = uint(-1) ^ (0xFFFFFFFF << 64);
    uint shifted = uint(r) << 64;
    assembly {
      mstore(n, or(shifted,
          and(mload(n), mask)))
    }
  }

  function writeIsBlack(uint32 n, uint32 b) internal pure {
    uint mask = uint(-1) ^ (0x80000000);
    assembly {
      mstore(n, or(b, and(mload(n), mask)))
    }
  }

  function writeKey(uint32 n, uint32 k) internal pure {
    uint mask = uint(-1) ^ (0xFFFFFFFF << 96);
    uint shifted = uint(k) << 96;
    assembly {
      mstore(n, or(shifted,
          and(mload(n), mask)))
    }
  }

  function writeValue32(uint32 n, uint32 v) internal pure {
    uint mask = uint(-1) ^ (0xFFFFFFFF << 128);
    uint shifted = uint(v) << 128;
    assembly {
      mstore(n, or(shifted,
          and(mload(n), mask)))
    }
  }

  function writeValue128(uint32 n, uint128 v) internal pure {
    uint mask = uint(-1) << 128;
    uint shifted = uint(v) << 128;
    assembly {
      mstore(n, or(shifted,
          and(mload(n), mask)))
    }
  }

  function newNode() internal pure returns (uint32 n) {
    assembly {
        n := mload(0x40) //load heap pointer
        mstore(0x40, add(n, 32)) //inc heap pointer by 32 bytes
    }
  }

  function nodeCopy(uint32 d, uint32 s) internal pure returns (uint32) {
    assembly {
      mstore(d, mload(s))
    }
  }

  //utilities
  
  function grandparent(uint32 n) internal pure returns (uint32) {
    uint32 p = parent(n);
    return parent(p);
  } 

  function sibling(uint32 n) internal pure returns (uint32) {
    uint32 p = parent(n);
    if (p == 0)
      return 0; //no sibling
    if (n == left(p))
      return right(p);
    else
      return left(p);
  }

  function uncle(uint32 n) internal pure returns (uint32) {
    uint32 p = parent(n);
    return sibling(p);
  }

  function rotateLeft(uint32 n) internal pure returns (uint32) {
    uint32 nnew = right(n);
    nodeCopy(right(n), left(nnew));
    nodeCopy(left(nnew), n);
    nodeCopy(parent(nnew), parent(n));
    nodeCopy(parent(n), nnew);
  }

  function rotateRight(uint32 n) internal pure returns (uint32) {
    uint32 nnew = left(n);
    nodeCopy(left(n), right(nnew));
    nodeCopy(right(nnew), n);
    nodeCopy(parent(nnew), parent(n));
    nodeCopy(parent(n), nnew);
  }

  // insert

  function insertRecurse(uint32 root, uint32 n) private pure {
    if (root != 0 && key(n) < key(root)) {
      if (left(root) != 0) {
        insertRecurse(left(root), n);
        return;
      }
      else
        writeLeft(root, n);
      //set node props
      writeParent(n, root);
      writeLeft(n, 0);
      writeRight(n, 0);
      writeIsBlack(n, 0);
    }
    else if (root != 0 && key(n) > key(root)) {
      if (right(root) != 0) {
        insertRecurse(right(root), n);
        return;
      }
      else
        writeRight(root, n);
      //set node props
      writeParent(n, root);
      writeLeft(n, 0);
      writeRight(n, 0);
      writeIsBlack(n, 0);
    }
    else {
      //overwrite value
      writeValue128(root, value128(n));
    }
  }


  function insertRepairTree(uint32 n) private pure {
    if (parent(n) == 0)
      insertCase1(n);
    else if (isBlack(parent(n)) != 0)
      insertCase2();
    else if (isBlack(uncle(n)) == 0)
      insertCase3(n);
    else
      insertCase4(n);
  }

  function insertCase1(uint32 n) private pure {
    //n is the root
    if (parent(n) == 0)
      writeIsBlack(n, 1);
  }

  function insertCase2() private pure {
    //parent is black, do nothing
  }

  function insertCase3(uint32 n) private pure {
    //parent and uncle are red
    writeIsBlack(parent(n), 1);
    writeIsBlack(uncle(n), 1);
    writeIsBlack(grandparent(n), 0);
    insertRepairTree(grandparent(n));
  }

  function insertCase4(uint32 n) private pure {
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

  function insertCase4step2(uint32 n) private pure {
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

  function removeOneChild(uint32 n) private pure {
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

  function deleteCase1(uint32 n) private pure {
    //n is the new root
    if (parent(n) != 0)
      deleteCase2(n);
  }

  function deleteCase2(uint32 n) private pure {
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

  function deleteCase3(uint32 n) private pure {
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

  function deleteCase4(uint32 n) private pure {
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

  function deleteCase5(uint32 n) private pure {
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

  function deleteCase6(uint32 n) private pure {
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

  function search(uint32 n, uint32 k) internal pure returns (uint32) {
    if (n == 0 || key(n) == k)
      return n;
    else if (key(n) < k)
      return search(left(n), k);
    return search(right(n), k);
  }

  /////////////////////////
  //User-facing functions//
  /////////////////////////

  function insert32(Tree memory tree, uint32 k, uint32 v) internal pure {
    uint32 n = newNode();
    writeKey(n, k);
    writeValue32(n, v);
    insertRecurse(tree.root, n);
    insertRepairTree(n);
    tree.root = n;
    while (parent(tree.root) != 0)
      tree.root = parent(tree.root);
  }

  //todo: in cases where root is modified, must update
  //todo: inc and dec size
  function remove(Tree memory tree, uint32 k) internal pure {
    uint32 n = search(tree.root, k);
    if (n == 0)
      return;
    if (left(n) == 0 && right(n) == 0)
    {
      uint32 p = parent(n);
      if (p == 0)
        tree.root = 0;
      else if (left(p) == n)
        writeLeft(p, 0);
      else
        writeRight(p, 0);
    }
    else removeOneChild(n);
  }

  function find32(Tree memory tree, uint32 k) internal pure returns (uint32) {
    return value32(search(tree.root, k));
  }
}
