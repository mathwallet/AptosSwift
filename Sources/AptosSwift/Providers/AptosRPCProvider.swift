//
//  AptosRPCProvider.swift
//  
//
//  Created by xgblin on 2022/8/2.
//

import Foundation
import PromiseKit

public struct AptosRPCProvider {
    public var nodeUrl:String
    var session:URLSession
    
    public init(nodeUrl: String) {
        self.nodeUrl = nodeUrl
        let config = URLSessionConfiguration.default
        self.session = URLSession(configuration: config)
    }
    
    public func fundAccount(address:String) -> Promise<[String]> {
        return self.POST(url: "https://faucet.devnet.aptoslabs.com/mint?amount=0&address=\(address.stripHexPrefix())", parameters: [] as! [String])
    }
    
    public func getChainInfo() -> Promise<ChainInfo> {
        return self.GET(url: nodeUrl)
    }
    
    public func getAccount(address:String) -> Promise<[AccountResult]> {
        return self.GET(url: "\(nodeUrl)/accounts/\(address)")
    }
    
    public func getAccountResources(address:String) -> Promise<[AccountResource]> {
        return self.GET(url: "\(nodeUrl)/accounts/\(address)/resources")
    }
    
    public func getAccountResource(address:String,resourceType:String) -> Promise<AccountResource> {
        return self.GET(url: "\(nodeUrl)/accounts/\(address)/resource/\(resourceType)")
    }
}

extension AptosRPCProvider {
    
    public func GET<T: Codable>(url:String) -> Promise<T> {
       let rp = Promise<Data>.pending()
       var task: URLSessionTask? = nil
        let queue = DispatchQueue(label: "aptos.get")
       queue.async {
           let encodeUrlString = url.addingPercentEncoding(withAllowedCharacters:
                       .urlQueryAllowed)
           var urlRequest = URLRequest(url: URL(string: encodeUrlString ?? "")!, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
           urlRequest.httpMethod = "GET"
           urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
           urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

           task = self.session.dataTask(with: urlRequest){ (data, response, error) in
               guard error == nil else {
                   rp.resolver.reject(error!)
                   return
               }
               guard data != nil else {
                   rp.resolver.reject(AptosError.providerError("Node response is empty"))
                   return
               }
               rp.resolver.fulfill(data!)
           }
           task?.resume()
       }
       return rp.promise.ensure(on: queue) {
               task = nil
           }.map(on: queue){ (data: Data) throws -> T in
               let decoder = JSONDecoder()
               decoder.keyDecodingStrategy = .convertFromSnakeCase
               if let resp = try? decoder.decode(T.self, from: data) {
                   return resp
               }
               throw AptosError.providerError("Parameter error or received wrong message")
           }
   }
    
    public func POST<T: Decodable>(url:String,parameters:Encodable) -> Promise<T> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        let queue = DispatchQueue(label: "aptos.post")
        queue.async {
            do {
//                debugPrint("POST \(providerURL)")
                let url = URL(string:url)
                var urlRequest = URLRequest(url: url!, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
                urlRequest.httpBody = try parameters.toJSONData()

                task = self.session.dataTask(with: urlRequest){ (data, response, error) in
                    guard error == nil else {
                        rp.resolver.reject(error!)
                        return
                    }
                    guard data != nil else {
                        rp.resolver.reject(AptosRpcProviderError.server(message: "Node response is empty"))
                        return
                    }
                    rp.resolver.fulfill(data!)
                }
                task?.resume()
            } catch {
                rp.resolver.reject(error)
            }
        }
        return rp.promise.ensure(on: queue) {
                task = nil
            }.map(on: queue){ (data: Data) throws -> T in
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                if let resp = try? decoder.decode(T.self, from: data) {
                    return resp
                }
                throw AptosError.providerError("Parameter error or received wrong message")
            }
    }
}

private extension Encodable {
    func toJSONData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
}


public enum AptosRpcProviderError: LocalizedError {
    case unknown
    case server(message: String)
    public var errorDescription: String? {
        switch self {
        case .server(let message):
            return message
        default:
            return "Unknown error"
        }
    }
}