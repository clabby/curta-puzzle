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
    function testFuzz_generate_succeeds() public {
        address _seed = ZERO_COOL;
        assertEq(puzzle.generate(_seed), uint256(keccak256(abi.encode(_seed, 0x7dffffffffff9b7c))));
    }

    // b4316a5
    function testVerify_solution() public {
        // TODO: Impl
        vm.startPrank(ZERO_COOL);
        uint256 start = puzzle.generate(ZERO_COOL);
        uint256 solution;

        // Phase 1.a
        solution |= (start & (0xFF << offset(0x12))) << 0x02 * 8;

        // Phase 1.b
        uint256 mask = 0xFF << offset(0x10);
        solution &= ~mask;
        solution |= (0x26 << offset(0x10));

        emit log_bytes32(bytes32(start));
        // Phase 2
        // 0xc0 << 67 + 0x53 << 8 + 0xb5 << 0
        uint256 bytecode = 0x030010030008030000FF00000000000000000000000000000000000000000000;
        bytecode |= ((start & 0xFF0000) >> 0x10) << offset(0x01);
        bytecode |= ((start & 0xFF00) >> 0x08) << offset(0x04);
        bytecode |= (start & 0xFF) << offset(0x07);
        solution |= bytecode;

        // Phase 3
        solution |= 0x0200;
        
        // Phase 4

        // Final
        solution |= 0x01;
        
        emit log_string(string.concat("solution: ", vm.toString(bytes32(solution))));
        assertTrue(puzzle.verify(start, solution));
        vm.stopPrank();
    }

    function offset(uint8 _length) internal pure returns (uint8 _bits) {
        _bits = (0x1f - _length) * 8;
    }
}
