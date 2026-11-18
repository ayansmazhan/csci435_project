// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MultiSig} from "../src/MultiSig.sol";

contract MultiSigTest is Test {
    MultiSig wallet;
    address o1 = makeAddr("owner1");
    address o2 = makeAddr("owner2");
    address o3 = makeAddr("owner3");
    address stranger = makeAddr("stranger");
    address payee = makeAddr("payee");

    function setUp() public {
        wallet = new MultiSig(o1, o2, o3);
        vm.deal(address(wallet), 10 ether);
    }

    // helper: owner1 submits a payment of 1 ether to payee
    function _submit() internal returns (uint256 id) {
        vm.prank(o1);
        id = wallet.submit(payee, 1 ether);
    }

    function _confirm(address owner, uint256 id) internal {
        vm.prank(owner);
        wallet.confirm(id);
    }

    // rule 1
    function test_ConstructorSetsOwners() public view {
        assertTrue(wallet.isOwner(o1));
        assertTrue(wallet.isOwner(o2));
        assertTrue(wallet.isOwner(o3));
        assertFalse(wallet.isOwner(stranger));
    }

    function test_ZeroOwnerReverts() public {
        vm.expectRevert();
        new MultiSig(o1, address(0), o3);
    }

    function test_DuplicateOwnerReverts() public {
        vm.expectRevert();
        new MultiSig(o1, o2, o1);
    }

    // rule 2
    function test_AcceptsPlainEth() public {
        vm.deal(stranger, 1 ether);
        vm.prank(stranger);
        (bool ok, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(address(wallet).balance, 11 ether);
    }

    // rule 3
    function test_SubmitAssignsIncreasingIds() public {
        assertEq(_submit(), 0);
        assertEq(_submit(), 1);
        assertEq(wallet.transactionCount(), 2);
        (address to, uint256 value, bool executed, uint256 n) = wallet.getTransaction(1);
        assertEq(to, payee);
        assertEq(value, 1 ether);
        assertFalse(executed);
        assertEq(n, 0);                          // submitting is not a confirmation
    }

    function test_SubmitByStrangerReverts() public {
        vm.prank(stranger);
        vm.expectRevert();
        wallet.submit(payee, 1 ether);
    }

    // rule 4
    function test_ConfirmRecords() public {
        uint256 id = _submit();
        _confirm(o2, id);
        assertTrue(wallet.isConfirmed(id, o2));
        assertFalse(wallet.isConfirmed(id, o1));
        (, , , uint256 n) = wallet.getTransaction(id);
        assertEq(n, 1);
    }

    function test_ConfirmByStrangerReverts() public {
        uint256 id = _submit();
        vm.prank(stranger);
        vm.expectRevert();
        wallet.confirm(id);
    }

    function test_DoubleConfirmReverts() public {
        uint256 id = _submit();
        _confirm(o2, id);
        vm.prank(o2);
        vm.expectRevert();
        wallet.confirm(id);
    }

    function test_ConfirmMissingTxReverts() public {
        vm.prank(o1);
        vm.expectRevert();
        wallet.confirm(0);                       // nothing submitted yet
    }

    // rule 5
    function test_ExecuteWithTwoConfirmations() public {
        uint256 id = _submit();
        _confirm(o1, id);
        _confirm(o3, id);
        vm.prank(o2);
        wallet.execute(id);
        assertEq(payee.balance, 1 ether);
        (, , bool executed, ) = wallet.getTransaction(id);
        assertTrue(executed);
    }

    function test_ExecuteWithOneConfirmationReverts() public {
        uint256 id = _submit();
        _confirm(o1, id);
        vm.prank(o1);
        vm.expectRevert();
        wallet.execute(id);
    }

    function test_ExecuteTwiceReverts() public {
        uint256 id = _submit();
        _confirm(o1, id);
        _confirm(o2, id);
        vm.startPrank(o1);
        wallet.execute(id);
        vm.expectRevert();
        wallet.execute(id);
        vm.stopPrank();
        assertEq(payee.balance, 1 ether);
    }

    function test_ConfirmAfterExecuteReverts() public {
        uint256 id = _submit();
        _confirm(o1, id);
        _confirm(o2, id);
        vm.prank(o1);
        wallet.execute(id);
        vm.prank(o3);
        vm.expectRevert();
        wallet.confirm(id);
    }

    function test_ExecuteByStrangerReverts() public {
        uint256 id = _submit();
        _confirm(o1, id);
        _confirm(o2, id);
        vm.prank(stranger);
        vm.expectRevert();
        wallet.execute(id);
    }

    function test_ExecuteMissingTxReverts() public {
        vm.prank(o1);
        vm.expectRevert();
        wallet.execute(5);
    }

    function test_ExecuteFailsWhenPaymentFails() public {
        vm.prank(o1);
        uint256 id = wallet.submit(payee, 100 ether);   // wallet only has 10 ether
        _confirm(o1, id);
        _confirm(o2, id);
        vm.prank(o1);
        vm.expectRevert();
        wallet.execute(id);
        (, , bool executed, ) = wallet.getTransaction(id);
        assertFalse(executed);
    }
}
