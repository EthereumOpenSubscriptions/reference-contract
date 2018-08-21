pragma solidity 0.4.24;
import "./SelfAuthorized.sol";
import "./registry.sol";

/// @title OwnerManager - Manages a set of owners and a threshold to perform actions.
/// @author Stefan George - <stefan@gnosis.pm>
/// @author Richard Meissner - <richard@gnosis.pm>
contract RegistryManager is SelfAuthorized {

    address public constant SENTINEL_REGISTRIES = address(0x1);

    mapping(address => address) internal registries;

    mapping(bytes => address) internal subscriptionHashToRegistry;

    uint256 registryCount;

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    function setupRegistries(address[] _registries)
    internal
    {
        // Initializing Safe registries.
        address currentRegistry = SENTINEL_REGISTRIES;
        for (uint256 i = 0; i < _registries.length; i++) {
            // Owner address cannot be null.
            address registry = _registries[i];
            require(registry != 0 && registry != SENTINEL_OWNERS, "Invalid registry address provided");
            // No duplicate registries allowed.
            require(registries[registry] == 0, "Duplicate owner address provided");
            registries[currentRegistry] = registry;
            currentRegistry = registry;
        }
        registries[currentRegistry] = SENTINEL_OWNERS;
        registryCount = _registries.length;
    }

    /// @dev Allows to add a new registry to the Safe and
    /// @param owner New registry address.
    function addRegistry(address _registry)
    public
    authorized
    {
        // Owner address cannot be null.
        require(_registry != 0 && _registry != SENTINEL_OWNERS, "Invalid owner address provided");
        // No duplicate owners allowed.
        require(registries[_registry] == 0, "Address is already an owner");
        registries[_registry] = registries[SENTINEL_OWNERS];
        registries[SENTINEL_OWNERS] = _registry;
        registryCount++;
    }

    /// @dev Allows to remove a registry from the Safe
    ///      This can only be done via a Safe transaction.
    /// @param prevRegistry Owner that pointed to the owner to be removed in the linked list
    /// @param owner Owner address to be removed.
    function removeRegistry(address _prevRegistry, address _registry)
    public
    authorized
    {
        // Only allow to remove an owner, if threshold can still be reached.
        require(registryCount - 1 >= _threshold, "New owner count needs to be larger than new threshold");
        // Validate owner address and check that it corresponds to owner index.
        require(_registry != 0 && _registry != SENTINEL_OWNERS, "Invalid owner address provided");
        require(registries[_prevRegistry] == _registry, "Invalid prevOwner, owner pair provided");
        registries[_prevRegistry] = registries[_registry];
        registries[_registry] = 0;
        registryCount--;
        // Change threshold if threshold was changed.
    }

    /// @dev Allows to swap/replace an owner from the Safe with another address.
    ///      This can only be done via a Safe transaction.
    /// @param _prevRegistry Registry that pointed to the owner to be replaced in the linked list
    /// @param _oldRegistry old Registry address to be replaced.
    /// @param _newRegistry New registry address.
    function swapRegistry(address _prevRegistry, address _oldRegistry, address _newRegistry)
    public
    authorized
    {
        // Owner address cannot be null.
        require(_newRegistry != 0 && _newRegistry != SENTINEL_OWNERS, "Invalid owner address provided");
        // No duplicate owners allowed.
        require(registries[_newRegistry] == 0, "Address is already an owner");
        // Validate oldOwner address and check that it corresponds to owner index.
        require(_oldRegistry != 0 && _oldRegistry != SENTINEL_OWNERS, "Invalid owner address provided");
        require(registries[_prevRegistry] == _oldRegistry, "Invalid prevOwner, owner pair provided");
        registries[_newRegistry] = registries[_oldRegistry];
        registries[_prevRegistry] = _newRegistry;
        registries[_oldRegistry] = 0;
    }


    function isOperator(address _operator, bytes _hash)
    public
    view
    returns (bool)
    {
        Registry R = Registry(registries[subscriptionHashToRegistry[_hash]]);

        return R.isOperator[_operator] != 0;
    }

    /// @dev Returns array of owners.
    /// @return Array of Safe owners.
    function getRegistries()
    public
    view
    returns (address[])
    {
        address[] memory array = new address[](registryCount);

        // populate return array
        uint256 index = 0;
        address currentRegistry = registries[SENTINEL_OWNERS];
        while(currentRegistry != SENTINEL_OWNERS) {
            array[index] = currentRegistry;
            currentRegistry = registries[currentRegistry];
            index ++;
        }
        return array;
    }
}
