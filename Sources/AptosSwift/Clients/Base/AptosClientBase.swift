//
//  AptosClientProvider.swift
//  
//
//  Created by xgblin on 2022/8/2.
//

import Foundation
import PromiseKit
import AnyCodable

public class AptosClientBase {
    public var url: URL
    private var session: URLSession
    
    public init(url: URL) {
        self.url = url
        self.session = URLSession(configuration: .default)
    }
    
    public func GET<T: Decodable>(path: String, parameters: [String: Any]? = nil) -> Promise<T> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        let queue = DispatchQueue(label: "aptos.get")
        queue.async {
            let url = self.url.appendPath(path).appendingQueryParameters(parameters)
//            debugPrint("GET \(url)")
            var urlRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
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
//            debugPrint(String(data: data, encoding: .utf8) ?? "")
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            if let resp = try? decoder.decode(T.self, from: data) {
               return resp
            }
            if let errorResult = try? decoder.decode(AptosClient.Error.self, from: data) {
                throw AptosError.resoultError(errorResult.errorCode, errorResult.message)
            }
            throw AptosError.providerError("Parameter error or received wrong message")
        }
    }
    
    public func POST<T: Decodable, K: Encodable>(path: String, parameters: K? = nil) -> Promise<T> {
        let body: Data? = (parameters != nil ? try? JSONEncoder().encode(parameters!) : nil)
        return POST(path: path, queryParameters: nil, body: body, headers: [:])
    }
    
    public func POST<T: Decodable>(path: String, queryParameters: [String : Any]? = nil, body: Data? = nil, headers: [String: String] = [:]) -> Promise<T> {
        let rp = Promise<Data>.pending()
        var task: URLSessionTask? = nil
        let queue = DispatchQueue(label: "aptos.post")
        queue.async {
            let url = self.url.appendPath(path).appendingQueryParameters(queryParameters)
//            debugPrint("POST \(url)")
            var urlRequest = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringCacheData)
            urlRequest.httpMethod = "POST"
            
            for key in headers.keys {
                urlRequest.setValue(headers[key], forHTTPHeaderField: key)
            }
            if !headers.keys.contains("Content-Type") {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
            if !headers.keys.contains("Accept") {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
            }
            urlRequest.httpBody = body
//            debugPrint(body?.toHexString() ?? "")

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
//            debugPrint(String(data: data, encoding: .utf8) ?? "")
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            if let resp = try? decoder.decode(T.self, from: data) {
                return resp
            }
            if let errorResult = try? decoder.decode(AptosClient.Error.self, from: data) {
                throw AptosError.resoultError(errorResult.errorCode, errorResult.message)
            }
            throw AptosError.providerError("Parameter error or received wrong message")
        }
    }
}
