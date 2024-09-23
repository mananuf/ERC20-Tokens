// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ERC1155 Token Implementation
 * @dev This is a fully self-contained ERC1155 implementation without import statements.
 *      It includes all necessary interfaces, libraries, and base contracts.
 */

/* ==========================================
   Interfaces
   ========================================== */

/**
 * @dev Interface of the ERC165 standard as defined in the EIP.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     *      `interfaceId`. See the corresponding EIP section to learn more about how
     *      these ids are created.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Interface of the ERC1155 standard as defined in the EIP.
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by each account in `accounts`.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Equivalent to multiple {safeTransferFrom} calls, with the transfer block being emitted as a {TransferBatch} event.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

/**
 * @dev Interface for the optional ERC1155MetadataExtension
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * Clients calling this function must replace the `\{id\}` substring with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

/**
 * @dev Interface for ERC1155 Errors (Custom Errors)
 */
interface IERC1155Errors {
    // Define custom errors for more efficient error handling
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 accountsLength);
    error ERC1155MissingApprovalForAll(address operator, address from);
    error ERC1155InvalidReceiver(address to);
    error ERC1155InvalidSender(address from);
    error ERC1155InvalidOperator(address operator);
    error ERC1155InsufficientBalance(address from, uint256 fromBalance, uint256 value, uint256 id);
}

/* ==========================================
   Libraries
   ========================================== */

/**
 * @dev Library for array operations.
 */
library Arrays {
    /**
     * @dev Returns the element at index `i` of array `arr`.
     *      Reverts if the index is out of bounds.
     */
    function unsafeMemoryAccess(uint256[] memory arr, uint256 i) internal pure returns (uint256) {
        // In Solidity >=0.8.0, accessing out-of-bounds will automatically revert
        return arr[i];
    }

    /**
     * @dev Returns the element at index `i` of array `arr`.
     *      Reverts if the index is out of bounds.
     */
    function unsafeMemoryAccess(address[] memory arr, uint256 i) internal pure returns (address) {
        // In Solidity >=0.8.0, accessing out-of-bounds will automatically revert
        return arr[i];
    }
}

/**
 * @dev Utility library for ERC1155 operations.
 */
library ERC1155Utils {
    /**
     * @dev Checks if the `to` address implements the `onERC1155Received` interface.
     *      Reverts if the check fails.
     */
    function checkOnERC1155Received(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal {
        // Implementation of ERC1155Receiver check
        bytes4 response = IERC1155Receiver(to).onERC1155Received(
            operator,
            from,
            id,
            value,
            data
        );
        if (response != IERC1155Receiver.onERC1155Received.selector) {
            revert("ERC1155: ERC1155Receiver rejected tokens");
        }
    }

    /**
     * @dev Checks if the `to` address implements the `onERC1155BatchReceived` interface.
     *      Reverts if the check fails.
     */
    function checkOnERC1155BatchReceived(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        // Implementation of ERC1155Receiver check
        bytes4 response = IERC1155Receiver(to).onERC1155BatchReceived(
            operator,
            from,
            ids,
            values,
            data
        );
        if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
            revert("ERC1155: ERC1155Receiver rejected tokens");
        }
    }
}

/* ==========================================
   ERC1155 Receiver Interface
   ========================================== */

/**
 * @dev Interface for contracts that want to support safeTransfers from ERC1155 asset contracts.
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type.
     *
     * Returns `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if successful.
     *
     * @param operator The address which initiated the transfer (i.e., msg.sender).
     * @param from The address which previously owned the token.
     * @param id The ID of the token being transferred.
     * @param value The amount of tokens being transferred.
     * @param data Additional data with no specified format.
     * @return bytes4 indicating the acceptance of the transfer.
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of multiple ERC1155 token types.
     *
     * Returns `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if successful.
     *
     * @param operator The address which initiated the batch transfer (i.e., msg.sender).
     * @param from The address which previously owned the token.
     * @param ids An array containing IDs of each token being transferred.
     * @param values An array containing amounts of each token being transferred.
     * @param data Additional data with no specified format.
     * @return bytes4 indicating the acceptance of the transfer.
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

/* ==========================================
   Context Contract
   ========================================== */

/**
 * @dev Provides information about the current execution context, including the
 *      sender of the transaction and its data. While these are generally available
 *      via msg.sender and msg.data, they should not be accessed in such a direct
 *      manner, since when dealing with meta-transactions the account sending and
 *      paying for execution may not be the actual sender (as far as an application
 *      is concerned).
 */
abstract contract Context {
    /**
     * @dev Returns the address of the sender.
     */
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Returns the calldata of the transaction.
     */
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/* ==========================================
   ERC165 Implementation
   ========================================== */

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Implements ERC165.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     *      `interfaceId`. Support of the actual interface is queried via {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/* ==========================================
   ERC1155 Implementation
   ========================================== */

/**
 * @dev Implementation of the basic standard multi-token as defined by the ERC1155 standard.
 *      Includes the Metadata URI extension.
 *
 *      This implementation is agnostic to the way tokens are created. This means
 *      that a supply mechanism has to be added in a derived contract using {_mint},
 *      {_mintBatch}, {_burn} or {_burnBatch}.
 *
 *      Supports the ERC1155MetadataURI extension.
 */
abstract contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI, IERC1155Errors {
    using Arrays for uint256[];
    using Arrays for address[];

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution
    string private _uri;

    /**
     * @dev Initializes the contract by setting a `uri` for all token types.
     *
     * @param uri_ The base URI for all token types.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
        // Register the supported interfaces
        _registerInterface(type(IERC1155).interfaceId);
        _registerInterface(type(IERC1155MetadataURI).interfaceId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Overrides the supportsInterface function to include ERC1155 and ERC1155MetadataURI interfaces.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * Returns the URI for token type `id`. This implementation returns the same URI for all token types,
     * relying on the token type ID substitution mechanism defined in the ERC1155 standard.
     *
     * Clients calling this function must replace the `\{id\}` substring with the actual token type ID.
     *
     * @param id The token type ID.
     * @return The URI string.
     */
    function uri(uint256 id ) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * @param account The address of the token holder.
     * @param id The token type ID.
     * @return The balance of tokens of type `id` held by `account`.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * @param accounts An array of token holders.
     * @param ids An array of token type IDs.
     * @return An array of balances corresponding to each account and token ID pair.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        if (accounts.length != ids.length) {
            revert ERC1155InvalidArrayLength(ids.length, accounts.length);
        }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts.unsafeMemoryAccess(i), ids.unsafeMemoryAccess(i));
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     *
     * Grants or revokes permission to `operator` to transfer the caller's tokens.
     *
     * @param operator The address to grant or revoke approval.
     * @param approved True to grant approval, false to revoke.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     *
     * @param account The address of the token holder.
     * @param operator The address of the operator.
     * @return True if `operator` is approved to transfer `account`'s tokens.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *
     * Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param id The token type ID.
     * @param amount The amount of tokens to transfer.
     * @param data Additional data with no specified format.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        address sender = _msgSender();
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert ERC1155MissingApprovalForAll(sender, from);
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     *
     * Transfers multiple types of tokens from `from` to `to`.
     *
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param ids An array of token type IDs.
     * @param amounts An array of amounts of tokens to transfer.
     * @param data Additional data with no specified format.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        address sender = _msgSender();
        if (from != sender && !isApprovedForAll(from, sender)) {
            revert ERC1155MissingApprovalForAll(sender, from);
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /* ==========================================
       Internal Functions
       ========================================== */

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param id The token type ID.
     * @param amount The amount of tokens to transfer.
     * @param data Additional data with no specified format.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }

        // Transfer the tokens
        _balances[id][from] -= amount;
        _balances[id][to] += amount;

        // Emit the event
        emit TransferSingle(_msgSender(), from, to, id, amount);

        // Check if the recipient is a contract and if it implements IERC1155Receiver
        if (to.code.length > 0) {
            ERC1155Utils.checkOnERC1155Received(_msgSender(), from, to, id, amount, data);
        }
    }

    /**
     * @dev Transfers multiple types of tokens from `from` to `to`.
     *
     * Emits a {TransferBatch} event.
     *
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param ids An array of token type IDs.
     * @param amounts An array of amounts of tokens to transfer.
     * @param data Additional data with no specified format.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        if (ids.length != amounts.length) {
            revert ERC1155InvalidArrayLength(ids.length, amounts.length);
        }

        // Transfer the tokens
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            _balances[id][from] -= amount;
            _balances[id][to] += amount;
        }

        // Emit the event
        emit TransferBatch(_msgSender(), from, to, ids, amounts);

        // Check if the recipient is a contract and if it implements IERC1155Receiver
        if (to.code.length > 0) {
            ERC1155Utils.checkOnERC1155BatchReceived(_msgSender(), from, to, ids, amounts, data);
        }
    }

    /**
     * @dev Sets a new URI for all token types.
     *
     * @param newuri The new base URI.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * @param to The address to mint tokens to.
     * @param id The token type ID.
     * @param amount The amount of tokens to mint.
     * @param data Additional data with no specified format.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }

        _balances[id][to] += amount;
        emit TransferSingle(_msgSender(), address(0), to, id, amount);

        if (to.code.length > 0) {
            ERC1155Utils.checkOnERC1155Received(_msgSender(), address(0), to, id, amount, data);
        }
    }

    /**
     * @dev Creates multiple tokens of different types, and assigns them to `to`.
     *
     * Emits a {TransferBatch} event.
     *
     * @param to The address to mint tokens to.
     * @param ids An array of token type IDs.
     * @param amounts An array of amounts of tokens to mint.
     * @param data Additional data with no specified format.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (ids.length != amounts.length) {
            revert ERC1155InvalidArrayLength(ids.length, amounts.length);
        }

        for (uint256 i = 0; i < ids.length; ++i) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(_msgSender(), address(0), to, ids, amounts);

        if (to.code.length > 0) {
            ERC1155Utils.checkOnERC1155BatchReceived(_msgSender(), address(0), to, ids, amounts, data);
        }
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`.
     *
     * Emits a {TransferSingle} event.
     *
     * @param from The address to burn tokens from.
     * @param id The token type ID.
     * @param amount The amount of tokens to burn.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }

        _balances[id][from] -= amount;
        emit TransferSingle(_msgSender(), from, address(0), id, amount);
    }

    /**
     * @dev Destroys multiple tokens of different types from `from`.
     *
     * Emits a {TransferBatch} event.
     *
     * @param from The address to burn tokens from.
     * @param ids An array of token type IDs.
     * @param amounts An array of amounts of tokens to burn.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        if (ids.length != amounts.length) {
            revert ERC1155InvalidArrayLength(ids.length, amounts.length);
        }

        for (uint256 i = 0; i < ids.length; ++i) {
            _balances[ids[i]][from] -= amounts[i];
        }

        emit TransferBatch(_msgSender(), from, address(0), ids, amounts);
    }

    /**
     * @dev Approves or removes `operator` as an operator for the caller.
     *
     * Emits an {ApprovalForAll} event.
     *
     * @param owner The address owning the tokens.
     * @param operator The address to grant or revoke approval.
     * @param approved True to grant approval, false to revoke.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if (operator == address(0)) {
            revert ERC1155InvalidOperator(address(0));
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /* ==========================================
       Events
       ========================================== */

    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
}

/* ==========================================
   IERC1155Receiver Implementation Example
   ========================================== */

/**
 * @dev Example implementation of the IERC1155Receiver interface.
 *      This contract accepts all token transfers.
 */
contract ERC1155ReceiverExample is IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address /* operator */,
        address /* from */,
        uint256 /* id */,
        uint256 /* value */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address /* operator */,
        address /* from */,
        uint256[] calldata /* ids */,
        uint256[] calldata /* values */,
        bytes calldata /* data */
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

/* ==========================================
   Complete ERC1155 Contract Without Imports
   ========================================== */

contract MyERC1155Token is ERC1155 {
    /**
     * @dev Constructor that initializes the contract with a base URI.
     *
     * @param baseURI The base URI for all token types.
     */
    constructor(string memory baseURI) ERC1155(baseURI) {
        // Optionally, mint initial tokens or perform other setup actions here
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * @param to The address to mint tokens to.
     * @param id The token type ID.
     * @param amount The amount of tokens to mint.
     * @param data Additional data with no specified format.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        _mint(to, id, amount, data);
    }

    /**
     * @dev Creates multiple tokens of different types, and assigns them to `to`.
     *
     * @param to The address to mint tokens to.
     * @param ids An array of token type IDs.
     * @param amounts An array of amounts of tokens to mint.
     * @param data Additional data with no specified format.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`.
     *
     * @param from The address to burn tokens from.
     * @param id The token type ID.
     * @param amount The amount of tokens to burn.
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        _burn(from, id, amount);
    }

    /**
     * @dev Destroys multiple tokens of different types from `from`.
     *
     * @param from The address to burn tokens from.
     * @param ids An array of token type IDs.
     * @param amounts An array of amounts of tokens to burn.
     */
    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public {
        _burnBatch(from, ids, amounts);
    }
}
