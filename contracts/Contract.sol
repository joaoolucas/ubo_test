// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Contract is ReentrancyGuard {
    event CourseAdded(
        string name,
        address courseOwner,
        uint256 totalStaked,
        address stakedTokenAddress,
        uint256 indexed courseId
    );
    event StudentAdded(uint256 indexed studentId);
    event ChallengeAdded(uint256 indexed challengeId);
    event SubmittedChallenge();
    event ValidatedSubmit(uint256 rewardAmount);

    enum Status {
        notSubmitted,
        Submitted,
        Validated,
        Claimed
    }

    struct Course {
        string name;
        bool isActive;
        address courseOwner;
        uint256 totalStaked;
        address stakedTokenAddress;
        mapping(address => bool) students;
        mapping(uint256 => Challenge) Challenges;
        uint256 studentId;
        uint256 courseId;
    }

    struct Challenge {
        mapping(address => Status) studentStatus;
        uint256 rewardAmount;
        uint256 challengeId;
        string storedAnswer;
    }

    Status public status;

    address owner;
    uint256 courseCount;
    uint256 studentCount;
    Course[] public allCourses;

    constructor() {
        owner = msg.sender;
    }

    mapping(uint256 => uint256) public challengeCount;
    mapping(address => bool) isProfessor;
    mapping(address => bool) hasAccount;
    mapping(uint256 => Course) public courses;

    //mapping of tokens allowed to be deposited on this contract
    //bytes32 -> symbol of the token
    //address -> address of the token contract
    mapping(bytes32 => address) public allowedListTokens;
    //it checks how much token has been deposited from each wallet using this contract
    mapping(address => mapping(bytes32 => uint256))
        public accountBalancesDeposited;

    //it allows a token to the contract
    function allowedListToken(bytes32 symbol, address tokenAddress) external {
        require(msg.sender == owner, "This function is not public");

        allowedListTokens[symbol] = tokenAddress;
    }

    //it deposits tokens to the contract
    function depositTokens(uint256 amount, bytes32 symbol) external {
        accountBalancesDeposited[msg.sender][symbol] += amount;
        ERC20(allowedListTokens[symbol]).transferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    function withdrawTokens(uint256 amount, bytes32 symbol)
        external
        nonReentrant
    {
        require(
            accountBalancesDeposited[msg.sender][symbol] >= amount,
            "Insufficent funds"
        );

        accountBalancesDeposited[msg.sender][symbol] -= amount;
        ERC20(allowedListTokens[symbol]).transfer(msg.sender, amount);
    }

    function addProfessor(address myAddress) public {
        isProfessor[myAddress] = true;
    }

    function addCourse(
        string memory name,
        address ownerAddress,
        uint256 stakeAmount,
        address tokenAddress
    ) public {
        require(
            !isProfessor[msg.sender],
            "You have to be a Professor to create a course"
        );
        courseCount++;
        courses[courseCount].name = name;
        courses[courseCount].isActive = true;
        courses[courseCount].courseOwner = ownerAddress;
        //Transfer tokenAddress stakeAmonunt to this contract
        courses[courseCount].totalStaked = stakeAmount;
        courses[courseCount].stakedTokenAddress = tokenAddress;
        courses[courseCount].courseId = courseCount;
        emit CourseAdded(
            name,
            ownerAddress,
            stakeAmount,
            tokenAddress,
            courseCount
        );
    }

    function addStudents() public {
        require(!hasAccount[msg.sender], "Address already has account");
        studentCount++;
        hasAccount[msg.sender] = true;
        courses[courseCount].studentId = studentCount;
        emit StudentAdded(studentCount);
    }

    function addChallenge(uint256 courseId, uint256 challengeReward) public {
        require(!isProfessor[msg.sender], "You're not a professor");
        challengeCount[courseId]++;
        courses[courseId].Challenges[challengeCount[courseId]];
        courses[courseId]
            .Challenges[challengeCount[courseId]]
            .rewardAmount = challengeReward;
        emit ChallengeAdded(challengeCount[courseId]);
    }

    function submitChallenge(
        string memory answer,
        uint256 courseId,
        uint256 challengeId
    ) public {
        courses[courseId].Challenges[challengeId].studentStatus[
            msg.sender
        ] = Status.Submitted;
        courses[courseId]
            .Challenges[challengeCount[courseId]]
            .storedAnswer = answer;
        emit SubmittedChallenge();
    }

    function validateSubmit(
        uint256 challengeId,
        uint256 courseId,
        uint256 score
    ) public {
        require(!isProfessor[msg.sender], "You're not a professor");
        require(
            courses[courseId].Challenges[challengeId].studentStatus[
                msg.sender
            ] == Status.Submitted
        );
        courses[courseId].Challenges[challengeId].studentStatus[
            msg.sender
        ] = Status.Validated;
        courses[courseId].Challenges[challengeCount[courseId]].rewardAmount =
            (score / 100) *
            courses[courseId].Challenges[challengeCount[courseId]].rewardAmount;
        emit ValidatedSubmit(
            courses[courseId].Challenges[challengeCount[courseId]].rewardAmount
        );
    }

    // function Claim(uint256 challengeId, uint256 courseId)
    //     public
    // // address tokenAddress
    // {
    //     require(
    //         courses[courseId].Challenges[challengeId].studentStatus[
    //             msg.sender
    //         ] == Status.Validated
    //     );
    //     courses[courseId].Challenges[challengeId].studentStatus[
    //         msg.sender
    //     ] = Status.Claimed;

    //     ERC20.transfer(
    //         msg.sender,
    //         courses[courseId].Challenges[challengeCount[courseId]].rewardAmount
    //     );
    // }
}

// function withdrawTokens(uint256 amount, bytes32 symbol) external nonReentrant {
//     require(
//         accountBalancesDeposited[msg.sender][symbol] >= amount,
//         "Insufficent funds"
//     );

//     accountBalancesDeposited[msg.sender][symbol] -= amount;
//     ERC20(allowedListTokens[symbol]).transfer(msg.sender, amount);
// }
