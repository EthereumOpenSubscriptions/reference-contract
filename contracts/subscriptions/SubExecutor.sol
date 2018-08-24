pragma solidity ^0.4.24;

import "../base/Executor.sol";
import "../common/SecuredTokenTransfer.sol";
import "./SubSecuredTokenTransferFrom.sol";
import "./SubEnum.sol";

contract SubExecutor is Executor, SubSecuredTokenTransferFrom{

    function executeSubscription(
        address receiver,
        uint value,
        bytes data,
        SubEnum.SubOperation operation,
        uint256 txGas,
        address delegateWallet
    )
    internal
    returns (bool success)
    {

      /* amount will need to be decoded from transaction data */
      uint amount = 0;

        if (operation == SubEnum.SubOperation.Call) {
            success = executeCall(receiver, value, data, txGas);
        } else if (operation == SubEnum.SubOperation.DelegateCall) {
            success = executeDelegateCall(receiver, data, txGas);
        } else if (operation == SubEnum.SubOperation.ERC20) {
            success = SecuredTokenTransfer.transferToken(paymentToken, receiver, amount);
        } else if (operation == SubEnum.SubOperation.ERC20Approve) {

            //parse data as such
            //split the bytes apart

            address sender = bytesToAddress(data, 0);

            address paymentToken = bytesToAddress(data, 20);

            success = SubSecuredTokenTransferFrom.transferFromToken(paymentToken, delegateWallet, receiver, amount);
        } else {
            success = false;
        }


    }

    function paySubmitter(
        uint256 gasPrice,
        address gasToken,
        uint256 startGas,
        uint256 dataGas,
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
                    require(SubSecuredTokenTransferFrom.transferFromToken(gasToken, delegateWallet, tx.origin, amount), "Could not pay gas costs with token");
                } else {
                  // solium-disable-next-line security/no-tx-origin
                    require(SecuredTokenTransfer.transferToken(gasToken, tx.origin, amount), "Could not pay gas costs with token");
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

}
