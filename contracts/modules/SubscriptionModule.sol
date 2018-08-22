pragma solidity 0.4.24;

import "../Enum.sol";
import "../Module.sol";
import "../iERC165.sol";
import "../GnosisSafePersonalEdition";


/// @title ERC-948 Subscription Module -
/// @author Andrew Redden - <andrew@groundhog.network>
contract SubscriptionModule is Module, iERC165, GnosisSafePersonalEdition {

    string public constant NAME = "ERC-948 Subscription Module";
    string public constant VERSION = "0.0.1";

    struct Meta {
        Enum.SubscriptionStatus status;
        uint nextWithdraw;
        bytes32 externalId;
    }

    mapping(bytes32 => Meta) public subscriptions;

    /// @dev Setup function sets initial storage of contract.
    /// @param accounts List of whitelisted accounts.
    function setup(address _registry)
    public
    {
        setManager();
        setRegistry(_registry);
        //setup registry that this takes executions from
    }


    function setRegistry(address _registry)
    authorized
    internal
    {
        registry = RegistryManager(_registry);
    }

    function createSubscription(
      address to,
      uint256 value,
      bytes data,
      Enum.Operation operation,
      uint256 safeTxGas,
      uint256 dataGas,
      uint256 gasPrice,
      address gasToken,
      uint externalId
      )
      public
      returns (bytes32 subscriptionHash)
      {

        Meta storage m;
        m.status = VALID;
        m.nextWithdraw = now;
        m.externalId = externalId;

        subscriptionHash = getSubscriptionHash(to, value, data, operation, safeTxGas, dataGas, gasPrice, gasToken);

        subscriptions[subscriptionHash] = m;

      }

    function execSubscriptionAndPaySubmitter(
        address to,
        uint256 value,
        bytes data,
        Enum.Operation operation,
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



        bytes32 txHash = getSubscriptionHash(to, value, data, operation, safeTxGas, dataGas, gasPrice, gasToken);

        checkSubscriptionHash(txHash, signatures);

        // Increase nonce and execute transaction.
        require(gasleft() >= safeTxGas, "Not enough gas to execute safe transaction");

        success = executeSubscription(to, value, data, operation, safeTxGas);

        uint lastWithdarw = subscriptions[txHash].nextWithdraw;

        /* period by which to increment withdraw period should be encoded in data field, leaving as 30 days for ease today */
        subscriptions[txHash].nextWithdraw = lastWithdraw + 30 days;

        if (!success) {
            emit ExecutionSubscriptionFailed(txHash);
        }

        if (gasPrice > 0) {

            address delegateWallet = address(0);

            if(operation == Enum.operation.ERC20Approve) {
                delegateWallet = bytesToAddress(data, 0);
            }

            paySubmitter(
                gasPrice,
                gasToken,
                delegateWallet
            );
        }
    }

/* txHash is declared but never used */
    function checkSubscriptionHash(bytes32 txHash, bytes signatures)
    internal
    view
    {
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint256 i;
        // Validate threshold is reached.
        for (i = 0; i < threshold; i++) {
            currentOwner = recoverKey(txHash, signatures, i);
            require(owners[currentOwner] != 0, "Signature not provided by owner");
            require(currentOwner > lastOwner, "Signatures are not ordered by owner address");
            lastOwner = currentOwner;
        }
    }


    function paySubmitter(
        uint256 gasPrice,
        address gasToken,
        address delegateWallet
    )
    internal
    {

        // We transfer the calculated tx costs to the tx.origin to avoid sending it to intermediate contracts that have made calls
        if (gasPrice > 0) {
            uint256 gasCosts = (startGas - gasleft()) + dataGas;
            uint256 amount = gasCosts * gasPrice;

            if (gasToken == address(0)) {
                // solium-disable-next-line security/no-tx-origin,security/no-send
                require(tx.origin.send(amount), "Could not pay gas costs with ether");
            } else {
                if (delegateWallet != address(0)) {
                  // solium-disable-next-line security/no-tx-origin
                    require(transferFromToken(gasToken, delegateWallet, tx.origin, amount), "Could not pay gas costs with token");
                } else {
                  // solium-disable-next-line security/no-tx-origin
                    require(transferToken(gasToken, tx.origin, amount), "Could not pay gas costs with token");
                }
            }
        }
    }





    function bytesToAddress(bytes _bytes, uint _start) internal pure returns (address oAddress) {
        require(_bytes.length >= (_start + 20), "_bytes is an incorrect length");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            oAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }
    }

    function bytesToUint(bytes _bytes, uint _start) internal pure returns (uint oUint) {
        require(_bytes.length >= (_start + 32), "_bytes is an incorrect length");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            oUint := mload(add(add(_bytes, 0x20), _start))
        }
    }
/* ---------------------------------------------------------------------------------------------------------
INTERFACE
------------------------------------------------------------------------------------------------------------ */
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
          if (subscriptions[subscriptionHash] == 0){
            return false;
          } else {
            return true;
          }
    }

      /** @dev returns the value of the subscription's status
      * @param bytes subscriptionHash is the identifier of the customer's subscription with its relevant details.
      * @return status is the enumerated status of the current subscription, 0 expired, 1 valid, 2 cancelled
      **/
    function getSubscriptionStatus(
        uint256 subscriptionHash
        )
        public
        view
        returns  (
          uint status
        ){
          sub = subscriptions[subscriptionHash];

          if (sub.status == expired){
            return 0;
          } else if (sub.status == active){
            return 1;
          } else if (sub.status == cancelled){
            return 2;
          }
    }

    function getSubscriptionHash(
        address recipient,
        uint256 value,
        bytes data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 dataGas,
        uint256 gasPrice,
        address gasToken
        )
        public
        view
        returns (
            bytes32
        ){
        return keccak256(
            abi.encodePacked(byte(0x19), byte(0), this, recipient, value, data, operation, safeTxGas, dataGas, gasPrice, gasToken)
        );
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
          /* this may be a naive impementation of the abi.encodePacked function */
          return keccak256(
              abi.encodePacked(byte(0x19), byte(0), this, subscriptionHash, status)
          );
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

    function executeSubscription(
        address receiver,
        uint value,
        bytes data,
        Enum.Operation operation,
        uint256 txGas,
        address delegateWallet
    )
    internal
    returns (bool success)
    {
        if (operation == Enum.SupportedTypes.Call) {
            success = executeCall(receiver, value, data, txGas);
        } else if (operation == Enum.Operation.DelegateCall) {
            success = executeDelegateCall(receiver, data, txGas);
        } else if (operation == Enum.Operation.ERC20) {
            success = transferToken(paymentToken, receiver, amount);
        } else if (operation == Enum.SupportedTypes.ERC20Approve) {

            //parse data as such
            //split the bytes apart

            address sender = bytesToAddress(data, 0);

            address paymentToken = bytesToAddress(data, 20);

            success = transferFromToken(paymentToken, delegateWallet, receiver, value);
        } else {
            success = false;
        }


    }

}
