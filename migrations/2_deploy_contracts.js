var RedBlackTree = artifacts.require("./RedBlackTree.sol");
var TreeTest = artifacts.require("./TreeTest.sol");

module.exports = function(deployer) {
  deployer.deploy(RedBlackTree);
  deployer.link(RedBlackTree, TreeTest);
  deployer.deploy(TreeTest);
}
