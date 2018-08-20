/// @title Enum - Collection of enums
/// Original concept from Richard Meissner - <richard@gnosis.pm> Gnosis safe contracts

pragma solidity ^0.4.24;

contract Enum {
    enum Operation {
        Call,
        DelegateCall,
        Create,
        ERC20,
        ERC20Approve
    }
    enum SubscriptionStatus {
        ACTIVE,
        PAUSED,
        CANCELLED,
        EXPIRED
    }
}
