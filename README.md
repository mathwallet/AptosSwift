# AptosSwift

## Installation

### Swift Package Manager

Add the AptosSwift package to your target dependencies in `Package.swift`:

```swift
import PackageDescription

let package = Package(
  name: "YourProject",
  dependencies: [
    .package(
        url: "https://github.com/mathwallet/AptosSwift",
        from: "0.0.5"
    ),
  ]
)
```

Then run the `swift build` command to build your project.

## Usage

### KeyPair

```swift
import AptosSwift

// Random keyPair
// try AptosKeyPairEd25519.randomKeyPair()

// KeyPair by mnemonics
let keyPair = try AptosKeyPairEd25519(mnemonics: "talk speak heavy can high immune romance language alarm sorry capable flame")

// KeyPair by privateKey
// try AptosKeyPairEd25519(privateKeyData: Data(hex: "2e0c19e199f9ba403e35817f078114bdcb6ea6341e749f02e4fea83ca055baa7"))

// PrivateKey => 0x2e0c19e199f9ba403e35817f078114bdcb6ea6341e749f02e4fea83ca055baa7
debugPrint(keyPair.privateKeyHex)

// PublicKey => 0x8d9f75b3a99e9d401a8e1c911fbc51e0d77920f8975f7df57ec34f9a6e454c43
debugPrint(keyPair.publicKey.hex)

// Address => 0x43cf7854347a34ec167a1980c324221005936d322683aa592bef6de7e46bc575
debugPrint(keyPair.address.address)
```

### Node API

#### Faucet Client

```swift
import AptosSwift

let faucetUrl = URL(string: "https://faucet.devnet.aptoslabs.com")!
let faucetClient = AptosFaucetClient(url: faucetUrl)
                
let address = try AptosAddress("0xde1cbede2618446ed917826e79cc30d93c39eeeef635f76225f714dc2d7e26b6")
let hashs = try faucetClient.fundAccount(address: address, amount: 1000000).wait()
```

#### Client

```swift
import AptosSwift

let nodeUrl = URL(string: "https://fullnode.devnet.aptoslabs.com")!
let client = AptosClient(url: nodeUrl)

let healthy = try client.healthy().wait()
debugPrint(healthy)

let ledgerInfo = try client.getLedgerInfo().wait()
debugPrint(ledgerInfo)

let address = try AptosAddress("0x689b6d1d3e54ebb582bef82be2e6781cccda150a6681227b4b0e43ab754834e5")
let accountData = try client.getAccount(address: address).wait()
debugPrint(accountData)

let resourceType = "0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>"
let accountResource = try client.getAccountResource(address: address, resourceType: resourceType).wait()
debugPrint(accountResource)

let coinStore = try accountResource.to(AptosClient.AccountResourceData.CoinStore.self)
debugPrint(coinStore)

let accountModules = try client.getAccountModules(address: try AptosAddress("0x1")).wait()
debugPrint(accountModules)

let block = try client.getBlock(0).wait()
debugPrint(block)
...
```

### Submit Transaction

```swift
import AptosSwift

let nodeUrl = URL(string: "https://fullnode.devnet.aptoslabs.com")!
let client = AptosClient(url: nodeUrl)

let keyPair = try AptosKeyPairEd25519.randomKeyPair()
let sequenceNumber = try client.getAccount(address: keyPair.address).wait().sequenceNumber
let chainId = try client.getLedgerInfo().wait().chainId
let to = try AptosAddress("0xde1cbede2618446ed917826e79cc30d93c39eeeef635f76225f714dc2d7e26b6")
let amount = UInt64(10)

let function = try AptosEntryFunction.natural(module: "0x1::coin",
                                                func: "transfer",
                                                typeArgs: [
                                                AptosTypeTag.Struct(AptosStructTag.fromString("0x1::aptos_coin::AptosCoin"))
                                                ],
                                                args: [
                                                to.data,
                                                try BorshEncoder().encode(amount)
                                                ]
)
let payload = AptosTransactionPayloadEntryFunction(value: function)
let date = UInt64(Date().timeIntervalSince1970 + 60)
let transaction = AptosRawTransaction(sender: keyPair.address,
                                      sequenceNumber: UInt64(sequenceNumber)!,
                                      maxGasAmount: 1000,
                                      gasUnitPrice: 1,
                                      expirationTimestampSecs: date,
                                      chainId: UInt8(chainId),
                                      payload: AptosTransactionPayload.EntryFunction(payload))
let signedtransaction = try transaction.sign(keyPair)
let result = try client.submitSignedTransaction(signedtransaction).wait()
debugPrint(result)
...
```

### Simulate Transaction

```swift
import AptosSwift

let nodeUrl = URL(string: "https://fullnode.devnet.aptoslabs.com")!
let client = AptosClient(nodeUrl: nodeUrl)

let keyPair = try AptosKeyPairEd25519.randomKeyPair()
let sequenceNumber = try client.getAccount(address: keyPair.address).wait().sequenceNumber
let chainId = try client.getLedgerInfo().wait().chainId
let to = try AptosAddress("0xde1cbede2618446ed917826e79cc30d93c39eeeef635f76225f714dc2d7e26b6")
let amount = UInt64(10)

let function = try AptosEntryFunction.natural(module: "0x1::coin",
                                                func: "transfer",
                                                typeArgs: [
                                                AptosTypeTag.Struct(AptosStructTag.fromString("0x1::aptos_coin::AptosCoin"))
                                                ],
                                                args: [
                                                to.data,
                                                try BorshEncoder().encode(amount)
                                                ]
)
let payload = AptosTransactionPayloadEntryFunction(value: function)
let date = UInt64(Date().timeIntervalSince1970 + 60)
let transaction = AptosRawTransaction(sender: keyPair.address,
                                      sequenceNumber: UInt64(sequenceNumber)!,
                                      maxGasAmount: 1000,
                                      gasUnitPrice: 1,
                                      expirationTimestampSecs: date,
                                      chainId: UInt8(chainId),
                                      payload: AptosTransactionPayload.EntryFunction(payload))
let result = try client.simulateTransaction(transaction, publicKey: keyPair.publicKey).wait()
debugPrint(result)
...
```
