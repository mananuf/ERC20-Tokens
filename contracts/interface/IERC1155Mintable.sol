// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC1155.sol";

/**
 * @title IERC1155Mintable
 * @dev Extends the standard IERC1155 interface with minting functions.
 */
interface IERC1155Mintable is IERC1155 {
    /**
     * @dev Mints `amount` tokens of token type `id` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - Caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev Mints multiple tokens of different types to `to`.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - Caller must have the `MINTER_ROLE`.
     */
    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}
