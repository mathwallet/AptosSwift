//
//  AptosKeyPair.swift
//
//
//  Created by xgblin on 2022/8/2.
//

import Foundation
import TweetNacl
import BIP39swift
import CryptoSwift

public struct AptosKeyPairEd25519 {
    public var mnemonics: String?
    public var secretKey: Data
    public var address: AptosAddress
    
    public var privateKeyData: Data {
        return secretKey[0..<32]
    }
    
    public var publicKeyData: Data {
        return secretKey[32..<64]
    }
    
    public var privateKeyHex: String {
        return self.privateKeyData.toHexString().addHexPrefix()
    }
    
    public var publicKey: AptosPublicKeyEd25519 {
        return try! AptosPublicKeyEd25519(self.publicKeyData)
    }
    
    public init(privateKeyData: Data) throws {
        try self.init(seed: privateKeyData)
    }
    
    public init(seed: Data) throws {
        guard seed.count == 32 else {
            throw AptosError.keyError("Invalid Seed")
        }
        let keyPair = try NaclSign.KeyPair.keyPair(fromSeed: seed)
        self.secretKey = keyPair.secretKey
        self.address = try AptosAddress(Data(keyPair.publicKey.bytes + [0x00]).sha3(.sha256))
    }
    
    public init(mnemonics: String, path: String = "m/44'/637'/0'/0'/0'") throws {
        guard let seed = BIP39.seedFromMmemonics(mnemonics) else {
            throw AptosError.keyError("Invalid Mnemonics")
        }
        let newSeed = NaclSign.KeyPair.deriveKey(path: path, seed: seed).key
        try self.init(seed: newSeed.subdata(in: 0..<32))
        self.mnemonics = mnemonics
    }
    
    public static func randomKeyPair() throws -> AptosKeyPairEd25519 {
        guard let mnemonic = try? BIP39.generateMnemonics(bitsOfEntropy: 128) else{
            throw AptosError.keyError("Invalid Mnemonics")
        }
        return try AptosKeyPairEd25519(mnemonics: mnemonic)
    }
}

// MARK: - Sign & Verify

extension AptosKeyPairEd25519 {
    public func sign(message: Data) throws -> Data {
         return try NaclSign.signDetached(message: message, secretKey: secretKey)
    }
    
    public func signVerify(message: Data, signature: Data) -> Bool {
        guard let ret = try? NaclSign.signDetachedVerify(message: message, sig: signature, publicKey: publicKeyData) else {
            return false
        }
        return ret
    }
}
