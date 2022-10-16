## 1. Create a Coin contract
```bash
## 创建Alice账号，注意后续地址改成你生成的Alice账号的地址
cd ~/aptos-core/aptos-move/move-examples/moon_coin
aptos init ## 成功后得到地址 0x691f13ebc3ea909654b8b364fefecd0e7b60e0e6fc5f98d870a1912aa673642d
aptos account fund-with-faucet --account 0x691f13ebc3ea909654b8b364fefecd0e7b60e0e6fc5f98d870a1912aa673642d --amount 10000000000000000000

## 发布MoonCoin
aptos move publish --named-addresses MoonCoin=0x691f13ebc3ea909654b8b364fefecd0e7b60e0e6fc5f98d870a1912aa673642d

## 给Alice注册CoinStore
aptos move run --function-id 0x1::managed_coin::register --type-args 0x691f13ebc3ea909654b8b364fefecd0e7b60e0e6fc5f98d870a1912aa673642d::moon_coin::MoonCoin

## 给Alice发放10000个MoonCoin
aptos move run --function-id 0x1::managed_coin::mint --type-args 0x691f13ebc3ea909654b8b364fefecd0e7b60e0e6fc5f98d870a1912aa673642d::moon_coin::MoonCoin --args address:0x691f13ebc3ea909654b8b364fefecd0e7b60e0e6fc5f98d870a1912aa673642d u64:10000

## 查看Alice的MoonCoin余额
aptos account list 
## 见到Alice的余额为
"0x1::coin::CoinStore<0x691f13ebc3ea909654b8b364fefecd0e7b60e0e6fc5f98d870a1912aa673642d::moon_coin::MoonCoin>": {
        "coin": {
          "value": "10000"
        },
        ...
}
```

## 2. Deploy launchpad
```bash
## 查看Alice私钥, 并复制Alice的私钥 0x137127b21acbec56c7351c06e2dfc647fd763ddca07f26b55dde1c59c2ff9e5d
cat ~/aptos-core/aptos-move/move-examples/moon_coin/.aptos/config.yaml

## 在mcr目录下创建Alice的profile
cd ~/mcr
aptos init --profile alice ## init的过程中，粘贴Alice的私钥

## 发布合约
aptos move publish --named-addresses mcr=alice --profile alice

## 查看alice的account, 能看到多了lauchpad的代码
aptos account list --profile alice

## 初始化
aptos move run --function-id 0x691f13ebc3ea909654b8b364fefecd0e7b60e0e6fc5f98d870a1912aa673642d::launchpad::init --profile alice
```

## 3. Create launchpad
```bash
aptos move run --function-id 0x691f13ebc3ea909654b8b364fefecd0e7b60e0e6fc5f98d870a1912aa673642d::launchpad::create --type-args 0x691f13ebc3ea909654b8b364fefecd0e7b60e0e6fc5f98d870a1912aa673642d::moon_coin::MoonCoin --args u64:1000 u64:200 u64:500 u64:1665473530 u64:1665483530 u64:1 u64:1000 u64:1 u8:1 --profile alice
```



