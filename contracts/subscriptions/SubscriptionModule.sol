pragma solidity 0.4.24;

import "./SubEnum.sol";
import "./SubExecutor.sol";
import "./iERC165.sol";
import "../base/Module.sol";
import "../base/OwnerManager.sol";
import "../common/SignatureDecoder.sol";



/// @title ERC-948 Subscription Module -
/// @author Andrew Redden - <andrew@groundhog.network>
/// @author Kevin Seagraves - <k.s.seagraves@gmail.com>
contract SubscriptionModule is Module, SubExecutor, SignatureDecoder {

    string public constant NAME = "ERC-948 Subscription Module";
    string public constant VERSION = "0.0.1";

    struct Meta {
        SubEnum.SubscriptionStatus status;
        uint nextWithdraw;
        bytes32 externalId;
    }

    mapping(bytes32 => Meta) public subscriptions;

    event ExecutionSubscriptionFailed(bytes32 _txHash);

    /// @dev Setup function sets initial storage of contract.
    function setup()
    public
    {
        setManager();
    }

    function createSubscription(
      address to,
      uint256 value,
      bytes data,
      SubEnum.SubOperation operation,
      uint256 safeTxGas,
      uint256 dataGas,
      uint256 gasPrice,
      address gasToken,
      bytes32 externalId
      )
      public
      returns (bytes32 subscriptionHash)
      {

        Meta memory m;
        m.status = SubEnum.SubscriptionStatus.VALID;
        m.nextWithdraw = now;
        m.externalId = externalId;

        subscriptionHash = getSubscriptionHash(to, value, data, operation, safeTxGas);

        subscriptions[subscriptionHash] = m;

      }

      /* @dev modifys the current subscription status
* @param uint256 subscriptionHash is the identifier of the customer's subscription with its relevant details.
* @param Enum.SubscriptionStatus status the new status of the subscription
* @param bytes signatures of the requested method being called
* @return success is the result of the subscription being paused
*/
    function modifyStatus(
        uint256 subscriptionHash,
        SubEnum.SubscriptionStatus status,
        bytes signatures
        )
        public
        returns (
          bool success
        ){

    }

    function execSubscriptionAndPaySubmitter(
        address to,
        uint256 value,
        bytes data,
        SubEnum.SubOperation operation,
        uint256 safeTxGas,
        uint256 dataGas,
        uint256 gasPrice,
        address gasToken,
        bytes signatures
    )
    public
    returns (
        bool success
    )
    {
        uint256 startGas = gasleft();



        bytes32 txHash = getSubscriptionHash(to, value, data, operation, safeTxGas);

        checkSubscriptionHash(txHash, signatures);

        // Increase nonce and execute transaction.
        require(gasleft() >= safeTxGas, "Not enough gas to execute safe transaction");

        success = SubExecutor.executeSubscription(to, value, data, operation, safeTxGas, delegateWallet);

        /* withdrawPeriod will need to be decoded from data */
        uint withdrawPeriod = 0;

        uint lastWithdraw = subscriptions[txHash].nextWithdraw;

        /* period by which to increment withdraw period should be encoded in data field, leaving as 30 days for ease today */
        subscriptions[txHash].nextWithdraw = lastWithdraw + withdrawPeriod;

        if (!success) {
            emit ExecutionSubscriptionFailed(txHash);
        }

        if (gasPrice > 0) {

            address delegateWallet = address(0);

            if(operation == SubEnum.SubOperation.ERC20Approve) {
                delegateWallet = SubExecutor.bytesToAddress(data, 0);
            }

            startGas = gasleft();

            SubExecutor.paySubmitter(
                gasPrice,
                gasToken,
                startGas,
                dataGas,
                delegateWallet
            );
        }
    }






/*  */
/*  */
/*        View only functions */
/*  */
/*  */


    /* @dev Checks if the subscription is valid.
      * @param bytes subscriptionHash is the identifier of the customer's subscription with its relevant details.
      * @return success is the result of whether the subscription is valid or not.
      */

    function isValidSubscription(
        bytes32 subscriptionHash
        )
        public
        view
        returns (
            bool success
        ){
          if (subscriptions[subscriptionHash].externalId == 0){
            return false;
          } else {
            return true;
          }
    }


    function checkSubscriptionHash(bytes32 txHash, bytes signatures)
    internal
    view
    {
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint256 i;
        uint256 threshold = OwnerManager(manager).getThreshold();

        // Validate threshold is reached.
        for (i = 0; i < threshold; i++) {
            currentOwner = recoverKey(txHash, signatures, i);
            require(OwnerManager(manager).isOwner(currentOwner), "Signature not provided by owner");
            require(currentOwner > lastOwner, "Signatures are not ordered by owner address");
            lastOwner = currentOwner;
        }
    }

/* @dev returns the value of the subscription's status
* @param bytes subscriptionHash is the identifier of the customer's subscription with its relevant details.
* @return status is the enumerated status of the current subscription, 0 expired, 1 valid, 2 cancelled
*/
    function getSubscriptionStatus(
        bytes32 subscriptionHash
        )
        public
        view
        returns  (
        uint status
        ){
            Meta memory sub = subscriptions[subscriptionHash];

            if (sub.status == SubEnum.SubscriptionStatus.EXPIRED){
              return 0;
            } else if (sub.status == SubEnum.SubscriptionStatus.VALID){
              return 1;
            } else if (sub.status == SubEnum.SubscriptionStatus.CANCELLED){
              return 2;
            }
    }

/* dataGas, gasPrice, and gasToken should be encoded in data. stack too deep. */
          function getSubscriptionHash(
              address recipient,
              uint256 value,
              bytes data,
              SubEnum.SubOperation operation,
              uint256 safeTxGas
              )
              public
              view
              returns (
                  bytes32
              ){
              return keccak256(
                  abi.encodePacked(byte(0x19), byte(0), this, recipient, value, data, operation, safeTxGas)
              );
          }

          /* @dev returns the hash of concatenated inputs that the owners user would sign with their public keys
        * @param address recipient the address of the person who is getting the funds.
        * @param uint256 value the value of the transaction
        * @return bytes32 returns the hash of concatenated inputs with the address of the contract holding the subscription hash
        */
      function getModifyStatusHash(
          bytes32 subscriptionHash,
          SubEnum.SubscriptionStatus status
          )
          public
          view
          returns (
              bytes32 modifyStatusHash
          ){
            /* this may be a naive impementation of the abi.encodePacked function */
            return keccak256(
                abi.encodePacked(byte(0x19), byte(0), this, subscriptionHash, status)
            );
      }



}
