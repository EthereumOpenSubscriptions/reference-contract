pragma solidity ^0.4.24;

import "./Enum.sol";

contract Subscriptions {

  /** @dev Checks if the subscription is valid.
    * @param bytes subscriptionHash is the identifier of the customer's subscription with its relevant details.
    * @return success is the result of whether the subscription is valid or not.
    **/

    function isValidSubscription(
        uint256 subscriptionHash
        )
        public
        view
        returns (
            bool success
        ){

    }

  /** @dev returns the value of the subscription
  * @param bytes subscriptionHash is the identifier of the customer's subscription with its relevant details.
  * @return status is the enumerated status of the current subscription, 0 expired, 1 active, 2 paused, 3 cancelled
  **/
    function getSubscriptionStatus(
        uint256 subscriptionHash
        )
        public
        view
        returns  (
          uint status
        ){

    }

              /** @dev returns the hash of cocatenated inputs to the address of the contract holding the logic.,
                * the owner would sign this hash and then provide it to the party for execution at a later date,
                * this could be viewed like a cheque, with the exception that unless you specifically
                * capture the hash on chain a valid signature will be executable at a later date, capturing the hash lets you modify the status to cancel or expire it.
                * @param address recipient the address of the person who is getting the funds.
                * @param uint256 value the value of the transaction
                * @param bytes data the data the user is agreeing to
                * @param uint256 txGas the cost of executing one of these transactions in gas(probably safe to pad this)
                * @param uint256 dataGas the cost of executing the data portion of the trasnaction(delegate calls etc)
                * @param uint 256 gasPrice the agreed upon gas cost of Execution of this subscription(cost incurment is up to implementation, ie, sender or reciever)
                * @param address gasToken address of the token in which gas will be compensated by, address(0) is ETH, only works in the case of an enscrow implementation)
                * @return bytes32, return the hash input arguments concatenated to the address of the contract that holds the logic.
                **/
    function getSubscriptionHash(
        address recipient,
        uint256 value,
        bytes data,
        Enum.Operation operation,
        uint256 txGas,
        uint256 dataGas,
        uint256 gasPrice,
        address gasToken
        )
        public
        view
        returns (
          bytes32 subscriptionHash
        ){

    }

                  /** @dev returns the hash of concatenated inputs that the owners user would sign with their public keys
  * @param address recipient the address of the person who is getting the funds.
  * @param uint256 value the value of the transaction
  * @return bytes32 returns the hash of concatenated inputs with the address of the contract holding the subscription hash
  **/
    function getModifyStatusHash(
        bytes32 subscriptionHash,
        Enum.SubscriptionStatus status
        )
        public
        view
        returns (
          bytes32 modifyStatusHash
        ){

    }

    /** @dev modifys the current subscription status
  * @param uint256 subscriptionHash is the identifier of the customer's subscription with its relevant details.
  * @param Enum.SubscriptionStatus status the new status of the subscription
  * @param bytes signatures of the requested method being called
  * @return success is the result of the subscription being paused
  **/
    function modifyStatus(
        uint256 subscriptionHash,
        Enum.SubscriptionStatus status,
        bytes signatures
        )
        public
        returns (
          bool success
        ){

    }

    /** @dev returns the hash of cocatenated inputs to the address of the contract holding the logic.,
  * the owner would sign this hash and then provide it to the party for execution at a later date,
  * this could be viewed like a cheque, with the exception that unless you specifically
  * capture the hash on chain a valid signature will be executable at a later date, capturing the hash lets you modify the status to cancel or expire it.
  * @param address recipient the address of the person who is getting the funds.
  * @param uint256 value the value of the transaction
  * @param bytes data the data the user is agreeing to
  * @param uint256 txGas the cost of executing one of these transactions in gas(probably safe to pad this)
  * @param uint256 dataGas the cost of executing the data portion of the trasnaction(delegate calls etc)
  * @param uint 256 gasPrice the agreed upon gas cost of Execution of this subscription(cost incurment is up to implementation, ie, sender or reciever)
  * @param address gasToken address of the token in which gas will be compensated by, address(0) is ETH, only works in the case of an enscrow implementation)
  * @param bytes signatures signatures concatenated that have signed the inputs as proof of valid execution
  * @return bool success something to note that a failed execution will still pay the issuer of the transaction for their gas costs.
  **/
    function executeSubscription(
        address to,
        uint256 value,
        bytes data,
        Enum.Operation operation,
        uint256 txGas,
        uint256 dataGas,
        uint256 gasPrice,
        address gasToken,
        bytes signatures
        )
        public
        returns (
          bool success
        ){

    }

}
