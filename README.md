# FairLaunch

## Introduction

FairLaunch is a decentralized launchpad that allows users to launch their own token and create their own initial token sale on Aptos. Users can launch their token at low cost with minimum blockchain programming skills.



## Structure

├── LICENSE
├── Move.toml
├── README.md
├── call_contract   //js script for setup launchpad
│   ├── common.ts
│   ├── output.key
│   ├── output.key.pub
│   ├── package.json
│   ├── sun_coin.move
│   ├── tsconfig.json
│   ├── yarn.lock
│   └── your_coin.ts
├── senario.md  //sample cmd script for comunicate with luanchpad module
├── sources
│   └── launchpad.move
└── tests
    └── launchpad_test.move