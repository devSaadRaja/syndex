const bn = require("bignumber.js");
const { ethers } = require("ethers");

bn.config({ EXPONENTIAL_AT: 999999, DECIMAL_PLACES: 40 });

function encodePriceSqrt(reserve1, reserve0) {
  return ethers
    .toBigInt(
      new bn(reserve1.toString())
        .div(reserve0.toString())
        .sqrt()
        .multipliedBy(new bn(2).pow(96))
        .integerValue(3)
        .toString()
    )
    .toString();
}

console.log(encodePriceSqrt(1000, 1000));

// ? ---------------------------------------------
// ? ---------------------------------------------
// ? ---------------------------------------------

const { nearestUsableTick } = require("@uniswap/v3-sdk");

const tick = 0;
const tickSpacing = 60;

const tickLower = nearestUsableTick(tick, tickSpacing) - tickSpacing * 2;
const tickUpper = nearestUsableTick(tick, tickSpacing) + tickSpacing * 2;

console.log("tickLower", tickLower);
console.log("tickUpper", tickUpper);
