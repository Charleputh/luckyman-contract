// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Iouhuang.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract OuHuang is
    Iouhuang,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC1155Holder
{
    using SafeMath for uint256;

    uint256 public ids;

    uint256 public createAmount;
    uint256 public submitAmount;

    uint256 public Base;

    uint256 public reward;

    struct property {
        uint256 head;
        uint256 background;
        uint256 shirt;
        uint256 hat;
        string name;
    }

    mapping(uint256 => property) public Chizi;

    mapping(uint256 => address) public ChiziList;

    mapping(uint256 => uint256) public ChiziMoney;

    mapping(uint256 => uint256) public ChiziMoneyHistory;

    mapping(uint256 => uint256) public ChiziCustom;

    mapping(uint256 => uint256) public ChiziOutTime;

    mapping(uint256 => uint256) public difficultyArr;

    uint256 public expireTime;

    address public fragmentAddress;

    uint256[3] public fragmentNumArr;

    uint256[3] public levelArr;

    address public luckNftAddress;

    function initialize() public initializer {
        __Ownable_init();
        ids = 0;
        createAmount = 10 ether;
        submitAmount = 1 ether;
        Base = 5 ether;
        reward = 0;
        expireTime = 2 days;
        levelArr = [4, 7, 10];
        fragmentNumArr = [3, 6, 9];
    }

    // 发布nft任务
    function create(
        uint256 hat,
        uint256 head,
        uint256 background,
        uint256 shirt,
        string memory name
    ) public payable override {
        require(msg.value >= createAmount, "invalid amount.");
        uint256 balance = ERC1155(fragmentAddress).balanceOf(msg.sender, 0);
        require(balance > 1, "invalid fragment amount.");
        uint256 maxNum = 1;
        uint256 level = 3;
        uint256[4] memory propertyArray = [hat, head, background, shirt];
        uint256 n = 0;
        while (n < 4) {
            if (propertyArray[n] > maxNum) {
                maxNum = propertyArray[n];
            }
            n++;
        }
        if (maxNum <= 6) {
            level = 2;
        }
        if (maxNum <= 3) {
            level = 1;
        }
        uint256 transferAmount = fragmentNumArr[level - 1];
        ERC1155(fragmentAddress).safeTransferFrom(
            msg.sender,
            address(this),
            0,
            transferAmount,
            "0x00"
        );
        ids = ids.add(1);
        Chizi[ids] = property(head, background, shirt, hat, name);
        ChiziList[ids] = msg.sender;
        ChiziMoney[ids] = msg.value;
        ChiziMoneyHistory[ids] = msg.value;
        ChiziCustom[ids] = 0;
        difficultyArr[ids] = levelArr[level - 1];
        uint256 _time = getTime();
        ChiziOutTime[ids] = _time + expireTime;
        emit Create(hat, head, background, shirt, ids, msg.value, name, _time);
    }

    function claim(uint256 id) public {
        require(ChiziList[id] == msg.sender);
        require(ChiziMoney[id] > 0);
        uint256 _time = getTime();
        require(ChiziOutTime[id] <= _time);
        uint256 allMoney = ChiziMoney[id].sub(Base);
        reward = reward.add(Base);
        payable(msg.sender).transfer(allMoney);
        ChiziMoney[id] = 0;
    }

    function submit(uint256 id) public payable override {
        require(msg.value == submitAmount, "submit amount error.");
        require(ChiziMoney[id] >= createAmount, "chizi money error.");
        uint256 _time = getTime();
        require(ChiziOutTime[id] > _time, "time error.");
        uint256 money = ChiziMoney[id].add(msg.value);
        ChiziMoney[id] = money;
        ChiziMoneyHistory[id] = money;
        ChiziCustom[id] = ChiziCustom[id].add(1);
        emit Submit(id, difficultyArr[id]);
    }

    function payForWiner(uint256 id, address from) public onlyOwner {
        uint256 allMoney = ChiziMoney[id].sub(Base);
        reward = reward.add(Base);
        payable(from).transfer(allMoney);
        ChiziMoney[id] = 0;
    }

    function getDetail(uint256 id)
        public
        view
        returns (
            property memory,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            Chizi[id],
            ChiziList[id],
            ChiziMoney[id],
            ChiziMoneyHistory[id],
            ChiziCustom[id],
            ChiziOutTime[id],
            difficultyArr[id]
        );
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lottery(uint256 id) public override {
        uint256 balance = ERC1155(fragmentAddress).balanceOf(msg.sender, 0);
        require(balance >= 1, "invalid fragment amount.");
        ERC1155(fragmentAddress).safeTransferFrom(
            msg.sender,
            address(this),
            0,
            1,
            "0x00"
        );
        if (id == 0) {
            emit Lottery(id);
        } else {
            address tokenOwner = ERC721(luckNftAddress).ownerOf(id);
            require(msg.sender == tokenOwner, "not owner.");
            emit Lottery(id);
        }
    }

    function setExpireTime(uint256 time) public {
        expireTime = time;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(reward);
    }

    function setFragmentAddress(address addr) public onlyOwner {
        fragmentAddress = addr;
    }

    function setLuckNftAddress(address addr) public onlyOwner {
        luckNftAddress = addr;
    }

    function setAmount(uint256 cAmount, uint256 sAmount, uint256 bAmount) public onlyOwner {
        createAmount = cAmount;
        submitAmount = sAmount;
        Base = bAmount;
    }
}
