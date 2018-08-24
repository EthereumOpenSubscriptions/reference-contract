pragma solidity 0.4.24;


/// @title Enum - Collection of enums
/// @author Richard Meissner - <richard@gnosis.pm>
contract SubEnum {
  enum SubOperation {
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
