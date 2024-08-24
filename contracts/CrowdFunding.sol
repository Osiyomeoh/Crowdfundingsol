// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Crowdfunding
 * @dev A simple crowdfunding contract where users can create campaigns,
 * donate to them, and request refunds if the campaign fails. 
 * The owner of the contract can withdraw any leftover funds.
 */
contract Crowdfunding {
    // Struct to represent a campaign
    struct Campaign {
        string title;              // The title of the campaign
        string description;        // A brief description of the campaign
        address payable benefactor; // The address of the person/organization receiving the funds
        uint goal;                 // The fundraising goal in wei
        uint deadline;             // The Unix timestamp for the campaign deadline
        uint amountRaised;         // The total amount of funds raised so far
        bool ended;                // Boolean to track if the campaign has ended
        bool successful;           // Boolean to indicate if the campaign was successful
    }

    // State variables
    address public owner;                      // Address of the contract owner
    uint public campaignCount = 0;             // Counter to track the number of campaigns created
    mapping(uint => Campaign) public campaigns; // Mapping to store campaigns by their ID
    mapping(uint => mapping(address => uint)) public contributions; // Nested mapping to track individual contributions per campaign

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

    /**
     * @dev Modifier to check if the caller is the owner of the contract.
     * Reverts the transaction if the caller is not the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    /**
     * @dev Modifier to check if a campaign exists with the given ID.
     * Reverts the transaction if the campaign does not exist.
     * @param id The campaign ID to check.
     */
    modifier campaignExists(uint id) {
        require(id > 0 && id <= campaignCount, "Campaign does not exist");
        _;
    }

    /**
     * @dev Constructor to set the contract owner to the address that deploys the contract.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Function to create a new campaign. Only the owner can create a campaign.
     * @param _title The title of the campaign.
     * @param _description A brief description of the campaign.
     * @param _benefactor The address that will receive the funds if the campaign is successful.
     * @param _goal The fundraising goal in wei.
     * @param _duration The duration of the campaign in seconds.
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        address payable _benefactor,
        uint _goal,
        uint _duration
    ) public {
        require(_goal > 0, "Fundraising goal should be greater than zero");
        require(_duration > 0, "Duration should be greater than zero");

        // Increment the campaign count to generate a new campaign ID
        campaignCount++;
        uint deadline = block.timestamp + _duration;

        // Create a new campaign and store it in the mapping
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

        // Emit an event to signal that a campaign has been created
        emit CampaignCreated(campaignCount, _title, _description, _benefactor, _goal, deadline);
    }

    /**
     * @dev Function to donate to a campaign.
     * @param _id The ID of the campaign to donate to.
     */
    function donate(uint _id) public payable campaignExists(_id) {
        Campaign storage campaign = campaigns[_id];

        // Ensure that the campaign is still active
        require(block.timestamp < campaign.deadline, "The campaign has ended");
        require(msg.value > 0, "Donation amount must be greater than zero");

        // Update the amount raised and the donor's contribution
        campaign.amountRaised += msg.value;
        contributions[_id][msg.sender] += msg.value;

        // Emit an event to signal that a donation has been received
        emit DonationReceived(_id, msg.sender, msg.value);
    }

    /**
     * @dev Function to end a campaign and transfer funds to the benefactor if successful.
     * @param _id The ID of the campaign to end.
     */
    function endCampaign(uint _id) public campaignExists(_id) {
        Campaign storage campaign = campaigns[_id];

        // Ensure the campaign has reached its deadline
        require(block.timestamp >= campaign.deadline, "Campaign deadline has not been reached");
        require(!campaign.ended, "Campaign has already ended");

        // Mark the campaign as ended
        campaign.ended = true;

        // If the goal was met or exceeded, transfer funds to the benefactor
        if (campaign.amountRaised >= campaign.goal) {
            campaign.successful = true;
            campaign.benefactor.transfer(campaign.amountRaised);
        }

        // Emit an event to signal that the campaign has ended
        emit CampaignEnded(_id, campaign.benefactor, campaign.amountRaised, campaign.successful);
    }

    /**
     * @dev Function to request a refund if the campaign was not successful.
     * Only contributors to the campaign can request a refund.
     * @param _id The ID of the campaign to request a refund from.
     */
    function requestRefund(uint _id) public campaignExists(_id) {
        Campaign storage campaign = campaigns[_id];

        // Ensure the campaign has ended and was not successful
        require(campaign.ended, "Campaign has not ended yet");
        require(!campaign.successful, "Campaign was successful, no refunds available");
        require(contributions[_id][msg.sender] > 0, "You have not contributed to this campaign");

        // Refund the contributor's donation
        uint amount = contributions[_id][msg.sender];
        contributions[_id][msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /**
     * @dev Function for the owner to withdraw leftover funds from the contract.
     * @param amount The amount of funds to withdraw in wei.
     */
    function withdrawFunds(uint amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance");
        payable(owner).transfer(amount);
    }

    /**
     * @dev Function to check the balance of the contract.
     * @return The contract's balance in wei.
     */
    function contractBalance() public view returns (uint) {
        return address(this).balance;
    }
}
