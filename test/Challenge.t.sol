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
        assertEq(puzzle.name(), "FizzBuzz");
    }

    /// @dev Tests that the `generate` function works as expected.
    function testFuzz_generate_succeeds(address _seed) public {
        assertEq(puzzle.generate(_seed), uint256(keccak256(abi.encode(_seed))));
    }

    function testVerify_solution() public {
        // TODO: Impl
        vm.startPrank(ZERO_COOL);
        uint256 start = puzzle.generate(ZERO_COOL);
        uint256 solution;

        // Phase 1.a
        solution |= (start & (0xFF << (0x1F - 0x12) * 8)) >> 0x07 * 8;

        // Phase 1.b
        uint256 mask = 0x0F << (0x1F - 0x19) * 8;
        solution &= ~mask;
        solution |= (0x05 << (0x1F - 0x19) * 8);

        // Phase 2
        // 0xc0 << 16 + 0xff << 8 + 0xee
        solution |= 0x03c01003ff0803ee00FF << (0x1F - 0x09) * 8;

        // Phase 3
        
        
        emit log_string(string.concat("solution: ", vm.toString(bytes32(solution))));
        assertTrue(puzzle.verify(start, solution));
        vm.stopPrank();
    }
}
