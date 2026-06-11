// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract KycAttestation {
    address public admin;

    struct Attestation {
        address subject;
        string level; // e.g. "basic", "enhanced"
        uint256 issuedAt;
        uint256 expiresAt;
        bool revoked;
    }
    mapping(address => bool) public isIssuer;
    mapping(bytes32 => Attestation) public attestations;
    uint256 public totalAttestations;

    event Attested(bytes32 indexed id, address indexed issuer, address indexed subject, string level);
    event Revoked(bytes32 indexed id);

    constructor(address) {
        admin = msg.sender;
        isIssuer[msg.sender] = true;
    }

    modifier onlyAdmin() { require(msg.sender == admin, "NOT_ADMIN"); _; }

    function setIssuer(address issuer, bool status) external onlyAdmin { isIssuer[issuer] = status; }

    function attest(address subject, string calldata level, uint256 duration) external returns (bytes32) {
        require(isIssuer[msg.sender], "NOT_ISSUER");
        bytes32 id = keccak256(abi.encodePacked(msg.sender, subject, block.timestamp, totalAttestations));
        attestations[id] = Attestation(subject, level, block.timestamp, block.timestamp + duration, false);
        totalAttestations++;
        emit Attested(id, msg.sender, subject, level);
        return id;
    }

    function revoke(bytes32 id) external {
        require(isIssuer[msg.sender], "NOT_ISSUER");
        attestations[id].revoked = true;
        emit Revoked(id);
    }

    function isValid(bytes32 id) external view returns (bool) {
        Attestation storage a = attestations[id];
        return a.subject != address(0) && !a.revoked && block.timestamp <= a.expiresAt;
    }
}
