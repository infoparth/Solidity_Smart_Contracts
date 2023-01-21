// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract WarrantyNFT is ERC721Enumerable, Ownable, AccessControl {
    

    mapping (uint256 => uint256) public creationTime;

    bool RepairWarranty = true ;

  // Struct to hold repair/replacement history for an NFT

     struct RepairHistory {
        uint256 timestamp;
        string description;
    }


     // Mapping from NFT ID to repair/replacement history

    mapping(uint256 => RepairHistory[]) public repairHistory;

    // Mapping from NFT ID to owner

    mapping(uint256 => address) public OwnerOf;

    bytes32 public constant Retailers = keccak256("Retailers");
    
    constructor(address _root) public ERC721("WarrantyNFT", "WARR") {
        _setupRole(DEFAULT_ADMIN_ROLE, _root);
        _setRoleAdmin(Retailers, DEFAULT_ADMIN_ROLE);

    }

     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
         return super.supportsInterface(interfaceId);
     }
     
        // Changing the Owner of the Contract

    function changeOwner(address _to)public onlyOwner{
        transferOwnership(_to);
    }

     modifier onlyManager() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Restricted to Managers.");
        _;
    }

    modifier onlyRetailer() {
        require(hasRole(Retailers, msg.sender), "Restricted to Retailers.");
        _;
    }

    // Adding a retailer, who can mint NFT's

    function addRetail(address account) public virtual onlyManager {
        grantRole(Retailers, account);
    }
    
    // Removing the person from the assigned the retailer role

     function removeRetai(address account) public virtual onlyManager {
        revokeRole(Retailers, account);
    }

    // Setting up a new Role Admin/ Manager

    function addManager(address account) public virtual onlyManager {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    //Renouncing the Manager perks

    function renounceManager() public virtual returns(bool){
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
        return (hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
    }

    // This function is used to mint a new NFT and assign it to a specific address.

    function mint(address _to) public  onlyRetailer  returns(uint256){

        // Generate a new, unique token ID for the NFT.

        uint256 tokenId = totalSupply() + 1;

        creationTime[tokenId] = block.timestamp;

        OwnerOf[tokenId]  = _to;

        // Mint the NFT and assign it to the specif//ied address.

        _mint(_to, tokenId);

        return tokenId;
    }

    // Makes he Warranty void 

    function repairWarrantyVoid() private   onlyRetailer  {
        RepairWarranty = false;
    }

    // Brings the Warranty back
        function repairWarrantyNotVoid() private  onlyRetailer {
        RepairWarranty = true;
    }

    // This function is used to check whether a specific address has a valid warranty NFT.

    function hasValidWarranty(address _owner) public view returns (bool) {

        // Check if the specified address has any NFTs of the "WAR" symbol.

        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) return false;

        // Check if the most recent NFT minted for this address is still within the warranty period.

        uint256 latestTokenId = tokenOfOwnerByIndex(_owner, tokenCount - 1);

        uint256 mintTimestamp = creationTime[latestTokenId];

        uint256 warrantyPeriod = 52 weeks; 

        if (block.timestamp < mintTimestamp + warrantyPeriod) 
       
        return true;

        // If the address has a valid NFT, return true.

        return false;
    }

    function transfer(address _to, uint256 _tokenId) public {

        // Ensure that the NFT exists and is owned by the caller

        require(_exists(_tokenId), "Token does not exist");

        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not the owner or approved to transfer the token");

        require(hasValidWarranty(msg.sender),"Your Warranty has expired");

        // Transfer ownership of the NFT to the new owner

        _transfer(msg.sender, _to, _tokenId);
    }

    function addRepair(uint256 _tokenId, string memory _description) public onlyRole(Retailers){

        // Ensure that the NFT exists and is owned by the caller

        require(_exists(_tokenId), "Token does not exist");

        require(_isApprovedOrOwner(msg.sender, _tokenId), "Caller is not the owner or approved to update the token");

        require(hasValidWarranty(msg.sender),"Your Warranty has expired");

        // Add a new entry to the repair/replacement history for the NFT

        repairHistory[_tokenId].push(RepairHistory(block.timestamp, _description));
    }
}

