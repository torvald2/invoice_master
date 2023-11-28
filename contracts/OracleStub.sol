// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

import "./InvoiceMatcher.sol";

contract OracleStub {

     function newOracleRequest(
        bytes4 callbackFunctionId,
        address callBackContract
    ) external  returns (bool) {

        InvoiceMatcher  matcher = InvoiceMatcher(msg.sender);
        matcher.swap(172769441);
        return true;
    }
}