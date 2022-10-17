## 1. Create a Coin contract
```bash
## 创建Alice账号，注意后续地址改成你生成的Alice账号的地址
cd ~/aptos-core/aptos-move/move-examples/moon_coin
aptos init --profile alice ## 成功后得到地址 0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6
aptos account fund-with-faucet --account 0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6 --amount 10000000000000000000

## 发布MoonCoin
aptos move publish --named-addresses MoonCoin=0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6 --profile alice

## 给Alice注册CoinStore
aptos move run --function-id 0x1::managed_coin::register --type-args 0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6::moon_coin::MoonCoin --profile alice

## 给Alice发放10000个MoonCoin
aptos move run --function-id 0x1::managed_coin::mint --type-args 0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6::moon_coin::MoonCoin --args address:0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6 u64:10000 --profile alice

## 查看Alice的MoonCoin余额
aptos account list --account 0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6
## 见到Alice的余额为
"0x1::coin::CoinStore<0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6::moon_coin::MoonCoin>": {
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
aptos move run --function-id 0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6::launchpad::init --profile alice
```

## 3. Create launchpad
```bash
aptos move run --function-id 0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6::launchpad::create --type-args 0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6::moon_coin::MoonCoin --args u64:1000 u64:200 u64:500 u64:1666014843 u64:1666016400 u64:1 u64:1000 u64:1 u8:1 --profile alice #请注意修改这里的起始和结束的时间戳
```

## 4. Buy coin
```bash
## create a profile for bob, 得到地址0x9c329fda104a2a0bcfac8603c458ebde00faed4307cc1bfd388f202cef3a0034
aptos init --profile bob
aptos account fund-with-faucet --account 0x9c329fda104a2a0bcfac8603c458ebde00faed4307cc1bfd388f202cef3a0034 --amount 10000000000000000000

## 给Bob安装CoinStore<MoonCoin>
aptos move run --function-id 0x1::managed_coin::register --type-args 0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6::moon_coin::MoonCoin --profile bob

## 调用buy方法
aptos move run --function-id  0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6::launchpad::buy --type-args 0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6::moon_coin::MoonCoin --args address:0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6 u64:1000 --profile bob

# 运行成功后查看bob的资源列表，看有没有Buy
aptos account list --profile bob 

{
  "0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6::launchpad::Buy<0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6::moon_coin::MoonCoin>": {
    "amount": "1000",
    "launchpad_owner": "0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6"
  }
}
```

## 5. Claim
After larnchpad end, claim token.
```bash
aptos move run --function-id  0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6::launchpad::claim --type-args 0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6::moon_coin::MoonCoin --args address:0xc34b348212d8e6080a9e1197f40707b9036d09fb3871d6ce7cf3932047e8d9e6 --profile bob
```

如果Claim成功，则Buy没了，MoonCoin的余额增加了
