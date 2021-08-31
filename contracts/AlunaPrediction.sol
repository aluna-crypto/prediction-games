pragma solidity 0.6.2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AlunaPrediction is Ownable {
    using SafeMath for uint256; // check what this will do for the contract
    using SafeERC20 for IERC20; // check what this will do to the contract

    address public rakeReceiver; // address of the contract that receives the rake
    address public voteToken; // address of the token used for voting

    uint256 public constant MAX_RAKE_PERCENTAGE = 10; // a constant max rake
    uint256 public rakePercentage = 5; // initial rake is 5%

    uint256 public totalUpVotes = 0; // amount of ALN voting for UP
    uint256 public totalDownVotes = 0; // amount of ALN voting for DOWN
    
    uint256 public startTime; // users can vote after this timestamp
    // TODO: maybe we can allow users to vote anytime before the endTime
    // as the outcome is not predictable anyway.

    uint256 public endTime; // users cannot vote after this timestamp

    mapping(address => uint256) public votedUp; // voteUp counters
    mapping(address => uint256) public votedDown; // voteDown counters
    mapping(address => uint256) public hasWithdrew; // already withdrew prize
    // TODO: check past of "withdraw" is it "withdrew" ??? lol

    booleam result; // stores final result ( true for UP false for DOWN )
    uint256 prizeAmount; // the final prize amount, defined during settlement

    constructor(address _voteToken, address _rakeReceiver) public {
        rakeReceiver = _rakeReceiver
    }

    function setRakePercentage(uint256 _rakePercentage) external onlyOwner {
        require(_rakePercentage <= MAX_RAKE_PERCENTAGE, "exceed max percent");
        rakePercentage = _rakePercentage;
    }

    // returns amount of UP votes made by given player
    function votesUpBy(address _player) public view returns (uint256) {
        return votedUp[address(_player)]
    }

    // returns amount of DOWN votes made by given player
    function votesDownBy(address _player) public view returns (uint256) {
        return votedDown[address(_player)]
    }

    function voteUp(uint256 amount) external {
        require(block.timestamp <= endTime, "end time already reached");

        votedUp[address(msg.sender)] = votedUp[address(msg.sender)].add(amount) 
        totalUpVotes = totalUpVotes.add(amount)

        voteToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function voteDown(uint256 amount) external {
        require(block.timestamp <= endTime, "end time already reached");

        votedDown[address(msg.sender)] = votedDown[address(msg.sender)].add(amount) 
        totalDownVotes = totalDownVotes.add(amount)

        voteToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * If isUp = true then all everyone who voted for UP will split the tokens
     * from who voted DOWN and vice versa.
    **/
    function settle(boolean _result) external onlyOwner {
        require(block.timestamp >= endTime, "cannot settle before end time");

        uint256 totalAmount = totalDownVotes.add(totalUpVotes) 
        uint256 rakeAmount = totalAmount.mul(rakeAmount).div(100)

        result = _result

        // if result is UP then prize is the DOWN votes
        // if result is DOWN then prize is the UP votes
        if(result) {
            prizeAmount = totalDownVotes
        } else {
            prizeAmount = totalUpVotes
        }

        prizeAmount = prizeAmount.mul(100-rakeAmount).div(100)

        voteToken.safeTransferFrom(address(this), rakeReceiver, rakeAmount);
    }

    function withdraw() external public {
        require(prizeAmount > 0, "no prize available")
        // TODO: how to check if a variable was previously set?
        // for instance check if "result" variable was previously set.

        require(hasWithdrew[address(msg.sender)] != true, "cannot withdrawl twice")
        hasWithdrew[address(msg.sender)] = true

        uint256 proportionalPrize = 0
        uint256 userProportional = 0

        if(result == true) {
            userProportional = votedUp[address(msg.sender)].div(totalUpVotes)
        } else {
            userProportional = votedDown[address(msg.sender)].div(totalDownVotes)
        }

        proportionalPrize = prizeAmount.mul(userProportional);

        voteToken.safeTransferFrom(address(this), address(msg.sender), proportionalPrize);
    }

}