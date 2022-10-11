// Copyright (c) Aptos
// SPDX-License-Identifier: Apache-2.0

import assert from "assert";
import fs from "fs";
import path from "path";
import { NODE_URL, FAUCET_URL } from "./common";
import { AptosAccount, AptosClient, TxnBuilderTypes, MaybeHexString, HexString, FaucetClient } from "aptos";
import { isUint8Array } from "util/types";
/**
  This example depends on the MoonCoin.move module having already been published to the destination blockchain.

  One method to do so is to use the CLI:
      * Acquire the Aptos CLI, see https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli
      * `yarn your_coin ~/aptos-core/aptos-move/move-examples/moon_coin`.
      * Open another terminal and `aptos move compile --package-dir ~/aptos-core/aptos-move/move-examples/moon_coin --save-metadata --named-addresses MoonCoin=<Alice address from above step>`.
      * Return to the first terminal and press enter.
 */

const readline = require("readline").createInterface({
  input: process.stdin,
  output: process.stdout,
});

class CoinClient extends AptosClient {
  constructor() {
    super(NODE_URL);
  }

  async callInit(minter: AptosAccount): Promise<string> {
    const rawTxn = await this.generateTransaction(minter.address(), {
      function: "0x56ea099947d3addf2caa52882686dbde1f277079721c1cc4210446101b6a2c0f::launchpad2::init",
      type_arguments: [],
      arguments: [],
    }, {
      gas_unit_price: "1000"
  });

    const bcsTxn = await this.signTransaction(minter, rawTxn);
    const pendingTxn = await this.submitTransaction(bcsTxn);

    return pendingTxn.hash;
  }

  async callCreate(minter: AptosAccount): Promise<string> {
    const rawTxn = await this.generateTransaction(minter.address(), {
      function: "0x56ea099947d3addf2caa52882686dbde1f277079721c1cc4210446101b6a2c0f::launchpad2::create",
      type_arguments: [`0xa03e0e9db3fa7ad6ce32ae4aea13354d6de71ab7de46a7db511a8beadc566916::moon_coin::MoonCoin`],
      arguments: [1000, 200,500,1665473530,1665483530],
    }, {
      gas_unit_price: "1000"
  });

    const bcsTxn = await this.signTransaction(minter, rawTxn);
    const pendingTxn = await this.submitTransaction(bcsTxn);

    return pendingTxn.hash;
  }
}



/** run our demo! */
async function main() {

  const client = new CoinClient();
  const faucetClient = new FaucetClient(NODE_URL, FAUCET_URL);

  // Create two accounts, Alice and Bob, and fund Alice but not Bob
  const key = new HexString("2322F3B32174245B238A24CDB0EE3BA56D0B7B4FEA9331CDDD4090368537ADEE");
  const myacc = new AptosAccount(key.toUint8Array(),"0x56ea099947d3addf2caa52882686dbde1f277079721c1cc4210446101b6a2c0f");

  console.log(`Start init`);
  let txnHash = await client.callInit(myacc);
  await client.waitForTransaction(txnHash, { checkSuccess: true });
  console.log(`Finish init`);

  console.log(`Start create`);
  txnHash = await client.callCreate(myacc);
  await client.waitForTransaction(txnHash, { checkSuccess: true });
  console.log(`Finish`);

}

if (require.main === module) {
  main().then((resp) => console.log(resp));
}
