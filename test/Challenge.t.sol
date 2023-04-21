pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { IPuzzle } from "src/IPuzzle.sol";

contract ChallengeTest is Test {
    address constant ZERO_COOL = address(0xdeadc0de);

    IPuzzle puzzle;

    function setUp() public {
        string[] memory args = new string[](3);
        args[0] = "huffc";
        args[1] = "-b";
        args[2] = "./src/Challenge.huff";
        bytes memory code = vm.ffi(args);

        assembly ("memory-safe") {
            sstore(puzzle.slot, create(0, add(code, 0x20), mload(code)))
        }
    }

    // @dev Tests that the `name` function works as expected.
    function testName() public {
        assertEq(puzzle.name(), "Antikythera");
    }

    /// @dev Tests that the `generate` function works as expected.
    function testGenerate() public {
        assertEq(puzzle.generate(ZERO_COOL), uint256(keccak256(abi.encode(ZERO_COOL, 0x7dffffffffff9b5d))));
    }

    /// @dev Tests that the solution works as expected for the given EOA.
    function testVerify() public {
        vm.startPrank(ZERO_COOL);

        // Generate the starting position of the puzzle.
        uint256 start = puzzle.generate(ZERO_COOL);
        emit log_bytes32(bytes32(start));

        // Create a variable to hold the solution.
        uint256 solution;

        // Phase 1.a
        // Set the 17th byte in solution to the 19th byte in the starting position.
        solution |= (start & (0xFF << offset(0x12))) << 0x02 * 8;

        // Phase 1.b & 4
        uint256 mask = 0xFF << offset(0x10);
        solution &= ~mask;
        // Note: We're storing 0010 in the upper bits because `gas` is divisible cleanly by 2 in phase 4.
        // 0110 in the lower bits because it shares set bits with PC in phase 1b's lower bits.
        solution |= (0x26 << offset(0x10));

        // Phase 2
        // In our VM, the easiest way to get a 3 byte number with the constraints is to just
        // shift 3 numbers.
        uint256 bytecode = 0x030010030008030000FF00000000000000000000000000000000000000000000;
        bytecode |= ((start & 0xFF0000) >> 0x10) << offset(0x01);
        bytecode |= ((start & 0xFF00) >> 0x08) << offset(0x04);
        bytecode |= (start & 0xFF) << offset(0x07);
        solution |= bytecode;

        // Phase 3
        // 0x3a iterations to get 1111 in the lowest 4 bits of our shuffled starting position.
        solution |= 0x3a00;

        // Final
        // Set the bool that is returned.
        solution |= 0x01;

        // Verify that the solution is correct.
        emit log_string(string.concat("solution: ", vm.toString(bytes32(solution))));
        assertTrue(puzzle.verify(start, solution));
        vm.stopPrank();
    }

    /// @dev Helper to get a shift offset.
    function offset(uint8 _length) internal pure returns (uint8 _bits) {
        _bits = (0x1f - _length) * 8;
    }
}
