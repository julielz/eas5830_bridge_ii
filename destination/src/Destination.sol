// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./BridgeToken.sol";

contract Destination is AccessControl {
    bytes32 public constant WARDEN_ROLE = keccak256("BRIDGE_WARDEN_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
	mapping( address => address) public underlying_tokens;
	mapping( address => address) public wrapped_tokens;
	address[] public tokens;

	event Creation( address indexed underlying_token, address indexed wrapped_token );
	event Wrap( address indexed underlying_token, address indexed wrapped_token, address indexed to, uint256 amount );
	event Unwrap( address indexed underlying_token, address indexed wrapped_token, address frm, address indexed to, uint256 amount );

    constructor( address admin ) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(CREATOR_ROLE, admin);
        _grantRole(WARDEN_ROLE, admin);
    }

	function wrap(address _underlying_token, address _recipient, uint256 _amount ) public onlyRole(WARDEN_ROLE) {
		//YOUR CODE HERE
    // look up the wrapped token for this underlying token
		address wrapped = underlying_tokens[_underlying_token];
		require(wrapped != address(0), "Token not registered");

		// mint the specified amount of tokens, to the recipient
		BridgeToken(wrapped).mint(_recipient, _amount);

		// emit wrap 
		emit Wrap(_underlying_token, wrapped, _recipient, _amount);
	}
	

	function unwrap(address _wrapped_token, address _recipient, uint256 _amount ) public {
		//YOUR CODE HERE
    // burn the specified amount of tokens from the sender
		BridgeToken(_wrapped_token).burnFrom(msg.sender, _amount);

		// get the underlying token address
		address underlying = BridgeToken(_wrapped_token).underlying();

		// emit an Unwrap event
		emit Unwrap(underlying, _wrapped_token, msg.sender, _recipient, _amount);
	}

	function createToken(address _underlying_token, string memory name, string memory symbol ) public onlyRole(CREATOR_ROLE) returns(address) {
		//YOUR CODE HERE
    // ensure this underlying token hasn't already been registered
		require(underlying_tokens[_underlying_token] == address(0), "Token already registered");

		// deploy a new BridgeToken contract
		BridgeToken newToken = new BridgeToken(_underlying_token, name, symbol);
		address wrapped = address(newToken);

		// store the mapping between the underlying and wrapped token
		underlying_tokens[_underlying_token] = wrapped;
		wrapped_tokens[wrapped] = _underlying_token;
		tokens.push(wrapped);

		// emit a Creation event
		emit Creation(_underlying_token, wrapped);

		// return the address of the new token
		return wrapped;
	}
}


