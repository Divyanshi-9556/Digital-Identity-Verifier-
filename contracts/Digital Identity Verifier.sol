// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Digital Identity Verifier
 * @dev A smart contract for managing and verifying digital identities on the blockchain
 * @author Your Name
 */
contract Project {
    // Struct to store identity information
    struct Identity {
        string name;
        string email;
        uint256 verificationLevel;
        bool isRegistered;
        uint256 registrationTimestamp;
        address[] verifiers;
        mapping(address => bool) hasVerified;
    }
    
    // Mapping from address to Identity
    mapping(address => Identity) private identities;
    
    // Mapping to track authorized verifiers
    mapping(address => bool) public authorizedVerifiers;
    
    // Contract owner
    address public owner;
    
    // Verification levels
    uint256 public constant LEVEL_BASIC = 1;
    uint256 public constant LEVEL_VERIFIED = 2;
    uint256 public constant LEVEL_PREMIUM = 3;
    
    // Events
    event IdentityRegistered(address indexed user, string name, uint256 timestamp);
    event IdentityVerified(address indexed user, address indexed verifier, uint256 newLevel);
    event VerifierAuthorized(address indexed verifier);
    event VerifierRevoked(address indexed verifier);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier onlyAuthorizedVerifier() {
        require(authorizedVerifiers[msg.sender], "Only authorized verifiers can call this function");
        _;
    }
    
    modifier onlyRegistered() {
        require(identities[msg.sender].isRegistered, "Identity not registered");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        authorizedVerifiers[msg.sender] = true; // Owner is default verifier
    }
    
    /**
     * @dev Core Function 1: Register a new digital identity
     * @param _name The name of the user
     * @param _email The email of the user
     */
    function registerIdentity(string memory _name, string memory _email) external {
        require(!identities[msg.sender].isRegistered, "Identity already registered");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_email).length > 0, "Email cannot be empty");
        
        Identity storage newIdentity = identities[msg.sender];
        newIdentity.name = _name;
        newIdentity.email = _email;
        newIdentity.verificationLevel = LEVEL_BASIC;
        newIdentity.isRegistered = true;
        newIdentity.registrationTimestamp = block.timestamp;
        
        emit IdentityRegistered(msg.sender, _name, block.timestamp);
    }
    
    /**
     * @dev Core Function 2: Verify an identity (only authorized verifiers)
     * @param _userAddress The address of the user to verify
     * @param _newLevel The new verification level to set
     */
    function verifyIdentity(address _userAddress, uint256 _newLevel) external onlyAuthorizedVerifier {
        require(identities[_userAddress].isRegistered, "Identity not registered");
        require(_newLevel >= LEVEL_BASIC && _newLevel <= LEVEL_PREMIUM, "Invalid verification level");
        require(!identities[_userAddress].hasVerified[msg.sender], "Already verified by this verifier");
        
        Identity storage identity = identities[_userAddress];
        
        // Add verifier to the list
        identity.verifiers.push(msg.sender);
        identity.hasVerified[msg.sender] = true;
        
        // Update verification level if higher
        if (_newLevel > identity.verificationLevel) {
            identity.verificationLevel = _newLevel;
        }
        
        emit IdentityVerified(_userAddress, msg.sender, identity.verificationLevel);
    }
    
    /**
     * @dev Core Function 3: Get identity information
     * @param _userAddress The address of the user to query
     * @return name The name of the user
     * @return email The email of the user
     * @return verificationLevel The current verification level
     * @return isRegistered Whether the identity is registered
     * @return registrationTimestamp When the identity was registered
     * @return verifierCount Number of verifiers who have verified this identity
     */
    function getIdentity(address _userAddress) external view returns (
        string memory name,
        string memory email,
        uint256 verificationLevel,
        bool isRegistered,
        uint256 registrationTimestamp,
        uint256 verifierCount
    ) {
        require(
            _userAddress == msg.sender || authorizedVerifiers[msg.sender],
            "Can only view own identity or must be authorized verifier"
        );
        
        Identity storage identity = identities[_userAddress];
        
        return (
            identity.name,
            identity.email,
            identity.verificationLevel,
            identity.isRegistered,
            identity.registrationTimestamp,
            identity.verifiers.length
        );
    }
    
    /**
     * @dev Add an authorized verifier (only owner)
     * @param _verifier The address to authorize as a verifier
     */
    function authorizeVerifier(address _verifier) external onlyOwner {
        require(_verifier != address(0), "Invalid verifier address");
        require(!authorizedVerifiers[_verifier], "Already authorized");
        
        authorizedVerifiers[_verifier] = true;
        emit VerifierAuthorized(_verifier);
    }
    
    /**
     * @dev Remove an authorized verifier (only owner)
     * @param _verifier The address to revoke verifier status
     */
    function revokeVerifier(address _verifier) external onlyOwner {
        require(authorizedVerifiers[_verifier], "Not an authorized verifier");
        require(_verifier != owner, "Cannot revoke owner");
        
        authorizedVerifiers[_verifier] = false;
        emit VerifierRevoked(_verifier);
    }
    
    /**
     * @dev Check if an address is registered
     * @param _userAddress The address to check
     * @return Whether the address has a registered identity
     */
    function isRegistered(address _userAddress) external view returns (bool) {
        return identities[_userAddress].isRegistered;
    }
    
    /**
     * @dev Get verification level of an identity
     * @param _userAddress The address to check
     * @return The verification level
     */
    function getVerificationLevel(address _userAddress) external view returns (uint256) {
        require(identities[_userAddress].isRegistered, "Identity not registered");
        return identities[_userAddress].verificationLevel;
    }
    
    /**
     * @dev Check if a verifier has verified a specific identity
     * @param _userAddress The user address
     * @param _verifier The verifier address
     * @return Whether the verifier has verified this identity
     */
    function hasVerifierVerified(address _userAddress, address _verifier) external view returns (bool) {
        return identities[_userAddress].hasVerified[_verifier];
    }
}
