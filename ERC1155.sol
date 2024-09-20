// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ERC1155
 * @dev A fully  implementation of the ERC1155 standard without external imports.
 */

/* ============================
         Interfaces
   ============================ */

/**
 * @dev Interface of the ERC165 standard, as defined in the EIP.
 */
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Interface of the ERC1155 standard as defined in the EIP.
 */
interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

/**
 * @dev Interface for the optional metadata functions from the ERC1155 standard.
 */
interface IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view returns (string memory);
}

/**
 * @dev Interface for contracts that want to handle ERC1155 token types.
 */
interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

/* ============================
         Errors
   ============================ */

// ERC165 Errors
error ERC165UnsupportedInterface(bytes4 interfaceId);

// ERC1155 Errors
error ERC1155InvalidArrayLength(uint256 idsLength, uint256 accountsLength);
error ERC1155MissingApprovalForAll(address operator, address account);
error ERC1155InvalidReceiver(address receiver);
error ERC1155InvalidSender(address sender);
error ERC1155InsufficientBalance(address account, uint256 balance, uint256 required, uint256 id);
error ERC1155InvalidOperator(address operator);

/* ============================
           Context
   ============================ */

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. 
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

/* ============================
           ERC165
   ============================ */

/**
 * @dev Implementation of the {IERC165} interface.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/* ============================
           ERC1155
   ============================ */

/**
 * @dev Implementation of the ERC1155 standard.
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // URI for all token types
    string private _uri;

    /**
     * @dev Initializes the contract by setting a `uri` for all token types.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism defined in the EIP.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        if (account == address(0)) revert ERC1155InvalidSender(address(0));
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        if (accounts.length != ids.length) {
            revert ERC1155InvalidArrayLength(ids.length, accounts.length);
        }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        address operator = _msgSender();
        if (from != operator && !isApprovedForAll(from, operator)) {
            revert ERC1155MissingApprovalForAll(operator, from);
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        address operator = _msgSender();
        if (from != operator && !isApprovedForAll(from, operator)) {
            revert ERC1155MissingApprovalForAll(operator, from);
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert ERC1155InvalidReceiver(address(0));

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) {
            revert ERC1155InsufficientBalance(from, fromBalance, amount, id);
        }
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev Batched version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert ERC1155InvalidReceiver(address(0));
        if (ids.length != amounts.length) revert ERC1155InvalidArrayLength(ids.length, amounts.length);

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            if (fromBalance < amount) {
                revert ERC1155InsufficientBalance(from, fromBalance, amount, id);
            }
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Mints `amount` tokens of token type `id` and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert ERC1155InvalidReceiver(address(0));

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev Batched version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (to == address(0)) revert ERC1155InvalidReceiver(address(0));
        if (ids.length != amounts.length) revert ERC1155InvalidArrayLength(ids.length, amounts.length);

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) revert ERC1155InvalidSender(address(0));

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        if (fromBalance < amount) {
            revert ERC1155InsufficientBalance(from, fromBalance, amount, id);
        }
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        // No need to perform acceptance check on burn
    }

    /**
     * @dev Batched version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `ids` and `amounts` must have the same length.
     * - `from` must have at least `amount` tokens of each token type `id`.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        if (from == address(0)) revert ERC1155InvalidSender(address(0));
        if (ids.length != amounts.length) revert ERC1155InvalidArrayLength(ids.length, amounts.length);

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            if (fromBalance < amount) {
                revert ERC1155InsufficientBalance(from, fromBalance, amount, id);
            }
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");

        // No need to perform acceptance check on burn
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism defined in the EIP.
     *
     * By this mechanism, any occurrence of the `{id}` substring in either the URI or any of the values in the JSON file at said URI will be replaced by clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/{id}.json` URI would be
     * interpreted by clients as `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json` for token type ID `0x4cce0`.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event, this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the zero address.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        if (operator == address(0)) revert ERC1155InvalidOperator(address(0));

        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens of token type `id` will be transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted for `to`.
     * - When `to` is zero, `amount` of ``from``'s tokens of token type `id` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, refer to the Solidity documentation.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        // Hook to be overridden by child contracts
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens of token type `id` will be transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted for `to`.
     * - When `to` is zero, `amount` of ``from``'s tokens of token type `id` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, refer to the Solidity documentation.
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        // Hook to be overridden by child contracts
    }

    /**
     * @dev Converts a single element into a one-element array.
     */
    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256;
        array[0] = element;
        return array;
    }

    /**
     * @dev Internal function to invoke {IERC1155Receiver-onERC1155Received} on a target address.
     *
     * `operator`, `from`, `to`, `id`, and `amount` have already been validated to be correct.
     *
     * This function reverts if `to` is a contract but does not correctly implement {IERC1155Receiver-onERC1155Received}.
     */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (isContract(to)) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert ERC1155InvalidReceiver(to);
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155InvalidReceiver(to);
            }
        }
    }

    /**
     * @dev Internal function to invoke {IERC1155Receiver-onERC1155BatchReceived} on a target address.
     *
     * `operator`, `from`, `to`, `ids`, and `amounts` have already been validated to be correct.
     *
     * This function reverts if `to` is a contract but does not correctly implement {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (isContract(to)) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert ERC1155InvalidReceiver(to);
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155InvalidReceiver(to);
            }
        }
    }

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

/* ============================
        ERC1155Token
   ============================ */

/**
 * @dev Extension of ERC1155 that adds minting and burning capabilities.
 */
contract ERC1155Token is ERC1155 {
    // Optional name and symbol for the token collection
    string public name;
    string public symbol;

    /**
     * @dev Initializes the contract by setting a `uri`, `name`, and `symbol` for the token collection.
     */
    constructor(
        string memory uri_,
        string memory name_,
        string memory symbol_
    ) ERC1155(uri_) {
        name = name_;
        symbol = symbol_;
    }

    /**
     * @dev Mints `amount` tokens of token type `id` to `to`.
     *
     * Requirements:
     *
     * - Caller must have the necessary permissions (e.g., owner).
     * - `to` cannot be the zero address.
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        // Implement access control as needed (e.g., onlyOwner)
        _mint(to, id, amount, data);
    }

    /**
     * @dev Mints multiple tokens of different types to `to`.
     *
     * Requirements:
     *
     * - Caller must have the necessary permissions (e.g., owner).
     * - `to` cannot be the zero address.
     * - `ids` and `amounts` must have the same length.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        // Implement access control as needed (e.g., onlyOwner)
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Burns `amount` tokens of token type `id` from `from`.
     *
     * Requirements:
     *
     * - Caller must have the necessary permissions (e.g., owner).
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external {
        // Implement access control as needed (e.g., onlyOwner)
        _burn(from, id, amount);
    }

    /**
     * @dev Burns multiple tokens of different types from `from`.
     *
     * Requirements:
     *
     * - Caller must have the necessary permissions (e.g., owner).
     * - `from` cannot be the zero address.
     * - `from` must have at least `amounts[i]` tokens of token type `ids[i]` for each `i`.
     */
    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        // Implement access control as needed (e.g., onlyOwner)
        _burnBatch(from, ids, amounts);
    }
}
