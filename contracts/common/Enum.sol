pragma solidity 0.4.24;


/// @title Enum - Collection of enums
/// @author Richard Meissner - <richard@gnosis.pm>
contract Enum {
    enum Operation {
        Call,
        DelegateCall,
        Create,
        ERC20,
        ERC20Approve
    }

    enum SubscriptionStatus {
        VALID,
        CANCELLED,
        EXPIRED
    }
}
