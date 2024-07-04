// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Faucet {
    address owner;

    struct Token {
        IERC20 token;
        uint lockTimePeriod;
        uint amountAllowed;
        bool enable;
    }
    struct AllTokenBalance {
        address tokenAddress;
        uint balance;
    }
    struct TokenLockTime {
        address tokenAddress;
        uint timeLock;
    }
    struct AllTokenDistributed {
        address tokenAddress;
        uint amount;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    mapping(address => Token) internal faucetToken;
    mapping(address => uint) internal tokensDistributed;
    mapping(address => mapping(address => uint)) internal usertokenlocktime;
    address[] internal tokenAddresses;
    AllTokenBalance[] internal allBalance;

    function addToken(
        address _tokenAddress,
        uint _lockTimePeriod,
        uint _amountAllowed,
        bool _enable
    ) public onlyOwner {
        require(
            faucetToken[_tokenAddress].token == IERC20(address(0)),
            "Token already present"
        );

        tokenAddresses.push(_tokenAddress);
        faucetToken[_tokenAddress] = Token({
            token: IERC20(_tokenAddress),
            lockTimePeriod: _lockTimePeriod,
            amountAllowed: _amountAllowed,
            enable: _enable
        });
    }

    function requestTokens(address tokenAddress) public {
        require(faucetToken[tokenAddress].enable == true, "Faucet not enabled");
        require(
            block.timestamp > usertokenlocktime[msg.sender][tokenAddress],
            "Lock time has not expired. Please try again later."
        );

        require(
            faucetToken[tokenAddress].token.balanceOf(address(this)) >=
                faucetToken[tokenAddress].amountAllowed,
            "Faucet does not have enough tokens"
        );

        usertokenlocktime[msg.sender][tokenAddress] =
            block.timestamp +
            faucetToken[tokenAddress].lockTimePeriod *
            1 days;

        faucetToken[tokenAddress].token.transfer(
            msg.sender,
            faucetToken[tokenAddress].amountAllowed
        );
        tokensDistributed[tokenAddress] += faucetToken[tokenAddress]
            .amountAllowed;
    }

    function getTokenBalance(address tokenAddress) public view returns (uint) {
        return faucetToken[tokenAddress].token.balanceOf(address(this));
    }

    function setAmountAllowed(
        uint newAmountAllowed,
        address tokenAddress
    ) public onlyOwner {
        faucetToken[tokenAddress].amountAllowed = newAmountAllowed;
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setEnablity(address tokenAddress, bool _enable) public onlyOwner {
        faucetToken[tokenAddress].enable = _enable;
    }

    function setLockTimePeriod(
        address tokenAddress,
        uint day
    ) public onlyOwner {
        faucetToken[tokenAddress].lockTimePeriod = day;
    }

    function getTotalTokenDistributed(
        address tokenAddress
    ) public view onlyOwner returns (uint) {
        return tokensDistributed[tokenAddress];
    }

    function getAllTokenBalance()
        public
        view
        returns (AllTokenBalance[] memory)
    {
        AllTokenBalance[] memory allTokenBalances = new AllTokenBalance[](
            tokenAddresses.length
        );
        for (uint i = 0; i < tokenAddresses.length; i++) {
            allTokenBalances[i] = AllTokenBalance({
                tokenAddress: tokenAddresses[i],
                balance: getTokenBalance(tokenAddresses[i])
            });
        }
        return allTokenBalances;
    }

    function getAllTokenDistributed()
        public
        view
        returns (AllTokenDistributed[] memory)
    {
        AllTokenDistributed[]
            memory allTokenDistributed = new AllTokenDistributed[](
                tokenAddresses.length
            );
        for (uint i = 0; i < tokenAddresses.length; i++) {
            allTokenDistributed[i] = AllTokenDistributed({
                tokenAddress: tokenAddresses[i],
                amount: getTotalTokenDistributed(tokenAddresses[i])
            });
        }
        return allTokenDistributed;
    }

    function getAmountAllowed(address tokenAddress) public view returns (uint) {
        return faucetToken[tokenAddress].amountAllowed;
    }

    function getlockTimeLeft(address tokenAddress) public view returns (uint) {
        if (block.timestamp > usertokenlocktime[msg.sender][tokenAddress]) {
            return 0;
        } else {
            return
                usertokenlocktime[msg.sender][tokenAddress] - block.timestamp;
        }
    }
}
