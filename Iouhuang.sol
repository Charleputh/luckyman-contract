// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface Iouhuang {
    event Create(
        uint256 hat,
        uint256 head,
        uint256 background,
        uint256 shirt,
        uint256 id,
        uint256 amount,
        string name,
        uint256 time
    );

    event Submit(uint256 id, uint256 difficulty);

    event Lottery(uint256 id);

    function create(
        uint256 hat,
        uint256 head,
        uint256 background,
        uint256 shirt,
        string memory name
    ) external payable;

    function submit(uint256 id) external payable;

    function lottery(uint256 id) external;
}
