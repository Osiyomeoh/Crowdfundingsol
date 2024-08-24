// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Crowdfunding {
    // Struct to represent a campaign
    struct Campaign {
        string title;
        string description;
        address payable benefactor;
        uint goal;
        uint deadline;
        uint amountRaised;
        bool ended;
        bool successful;
    }

    // State variables
    address public owner;
    uint public campaignCount = 0;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public contributions;

    // Events
    event CampaignCreated(
        uint id,
        string title,
        string description,
        address benefactor,
        uint goal,
        uint deadline
    );
    
    event DonationReceived(uint id, address donor, uint amount);
    
    event CampaignEnded(uint id, address benefactor, uint amountRaised, bool successful);

    // Modifier to check if the caller is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // Modifier to check if a campaign exists
    modifier campaignExists(uint id) {
        require(id > 0 && id <= campaignCount, "Campaign does not exist");
        _;
    }

    // Constructor to set the owner
    constructor() {
        owner = msg.sender;
    }

    // Function to create a new campaign
    function createCampaign(
        string memory _title,
        string memory _description,
        address payable _benefactor,
        uint _goal,
        uint _duration
    ) public {
        require(_goal > 0, "Fundraising goal should be greater than zero");
        require(_duration > 0, "Duration should be greater than zero");

        campaignCount++;
        uint deadline = block.timestamp + _duration;

        campaigns[campaignCount] = Campaign(
            _title,
            _description,
            _benefactor,
            _goal,
            deadline,
            0,
            false,
            false
        );

        emit CampaignCreated(campaignCount, _title, _description, _benefactor, _goal, deadline);
    }

    // Function to donate to a campaign
    function donate(uint _id) public payable campaignExists(_id) {
        Campaign storage campaign = campaigns[_id];

        require(block.timestamp < campaign.deadline, "The campaign has ended");
        require(msg.value > 0, "Donation amount must be greater than zero");

        campaign.amountRaised += msg.value;
        contributions[_id][msg.sender] += msg.value;

        emit DonationReceived(_id, msg.sender, msg.value);
    }

    // Function to end a campaign and transfer funds to the benefactor
    function endCampaign(uint _id) public campaignExists(_id) {
        Campaign storage campaign = campaigns[_id];

        require(block.timestamp >= campaign.deadline, "Campaign deadline has not been reached");
        require(!campaign.ended, "Campaign has already ended");

        campaign.ended = true;
        if (campaign.amountRaised >= campaign.goal) {
            campaign.successful = true;
            campaign.benefactor.transfer(campaign.amountRaised);
        }

        emit CampaignEnded(_id, campaign.benefactor, campaign.amountRaised, campaign.successful);
    }

    // Function to request a refund if the campaign was not successful
    function requestRefund(uint _id) public campaignExists(_id) {
        Campaign storage campaign = campaigns[_id];

        require(campaign.ended, "Campaign has not ended yet");
        require(!campaign.successful, "Campaign was successful, no refunds available");
        require(contributions[_id][msg.sender] > 0, "You have not contributed to this campaign");

        uint amount = contributions[_id][msg.sender];
        contributions[_id][msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // Function for the owner to withdraw leftover funds (optional)
    function withdrawFunds(uint amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance");
        payable(owner).transfer(amount);
    }

    // Function to get the balance of the contract (for transparency)
    function contractBalance() public view returns (uint) {
        return address(this).balance;
    }
}
