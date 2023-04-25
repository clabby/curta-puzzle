pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { IPuzzle } from "src/IPuzzle.sol";

interface ICurta {
    function addPuzzle(IPuzzle _puzzle, uint256 _tokenId) external;
}

contract DeployPuzzle is Script {
    address constant ZERO_COOL = address(0xA41FD464c84B5AfcfA9fe58545564d49EC04c1D3);

    ICurta constant curta = ICurta(0x0000000006bC8D9e5e9d436217B88De704a9F307);

    function run() external {
        string[] memory cmds = new string[](3);
        cmds[0] = "huffc";
        cmds[1] = "-b";
        cmds[2] = "./src/Challenge.huff";
        bytes memory code = vm.ffi(cmds);

        vm.startBroadcast(ZERO_COOL);
        IPuzzle puzzle;
        assembly {
            puzzle := create(0, add(code, 0x20), mload(code))
        }

        curta.addPuzzle(puzzle, 40);
        vm.stopBroadcast();
    }
}
