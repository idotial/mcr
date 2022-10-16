## 1. Create a Coin contract
```bash
## 创建Alice账号
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

## 2. Create launchpad
```bash
## 查看Alice私钥
cat ~/aptos-core/aptos-move/move-examples/moon_coin/.aptos/config.yaml
cd ~/mcr
cp ~/aptos-core/aptos-move/move-examples/moon_coin/.aptos ./
```



