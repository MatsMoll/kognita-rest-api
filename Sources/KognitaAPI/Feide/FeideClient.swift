//
//  File.swift
//  
//
//  Created by Mats Mollestad on 17/12/2020.
//

import Foundation
import Vapor
import KognitaCore

/// A protocol defining the functionality needed when connecting to the feide service
public protocol FeideClientRepresentable {
    
    /// Redirects to the Feide login page
    /// - Parameter req: The HTTP request to redirect
    /// - Returns: A response with a redirect
    func loginRedirect(for req: Request) -> Response
    
    /// Fetches a `AccessToken` based on a `Grant` given by the user
    /// - Parameters:
    ///   - req: The request assosiated with the new fetch
    ///   - grant: The user `Grant`
    /// - Throws: If the `FeideConfig` is unable to generate a basic auth key
    /// - Returns: A future `FeideClient.AccessToken`
    func token(with grant: Feide.Grant) throws -> EventLoopFuture<Feide.AccessToken>
    
    /// Fetches the user info associated with a token
    /// - Parameters:
    ///   - req: The HTTP requesting the user info
    ///   - token: The user token represented as a `AccessToken`
    /// - Returns: A future `UserInfo`
    func userInfo(with token: Feide.AccessToken) -> EventLoopFuture<Feide.UserInfo>
    
    /// Ends the feide session
    /// - Parameter req: The HTTP request
    func endSession(for req: Request) -> Response
    
    /// Returns all the subjects a user are regestrated for
    /// - Parameters:
    ///   - userToken: The users access token
    ///   - req: The request
    func subjects(userToken: String) -> EventLoopFuture<[Feide.Subject]>
}

/// A Client that connects to a Feide client
public struct FeideClient: FeideClientRepresentable {
    
    /// The configuration needed in order to connect to the Feide service
    public struct Config {
        /// The base uri used to authenticate to the service
        let authBaseUri: String
        
        /// The base uri used to when accessing the Fedie API
        let apiBaseUri: String
        
        /// The client ID registrated in the Feide portal
        let clientID: String
        
        /// The client secret identifing the service in the Feide portal
        let clientSecret: String
        
        /// The callback uri that Feide returns to
        let callbackUri: String
        
        /// A base 64 encoded string containg the client id and client secret identifying needed to access the service
        var basicAuth: String? {
            "\(clientID):\(clientSecret)".data(using: .utf8)?.base64EncodedString()
        }
    }
    
    /// The configuration of the `FeideClient`.
    /// This can be changed in order to work in a local-, dev- or prod-env.
    let config: Config
    
    /// A HTTP-client that makes further requests
    let client: Client
    
    /// Fetch the JWKS in order to use the JWT
    /// - Parameter req: The request that will request the JWKS
    /// - Returns: A future `JWKS`
    func jwks(for req: Request) -> EventLoopFuture<Feide.JWKS> {
        req.client.get("\(config.authBaseUri)/.well-known/openid-configuration")
            .flatMapThrowing { try $0.content.decode(Feide.JWKS.self) }
    }
    
    /// Redirects to the Feide login page
    /// - Parameter req: The HTTP request to redirect
    /// - Returns: A response with a redirect
    public func loginRedirect(for req: Request) -> Response {
        req.redirect(to: "\(config.authBaseUri)/oauth/authorization?client_id=\(config.clientID)&response_type=code&redirect_uri=\(config.callbackUri)")
    }
    
    /// Fetches a `AccessToken` based on a `Grant` given by the user
    /// - Parameters:
    ///   - req: The request assosiated with the new fetch
    ///   - grant: The user `Grant`
    /// - Throws: If the `FeideConfig` is unable to generate a basic auth key
    /// - Returns: A future `FeideClient.AccessToken`
    public func token(with grant: Feide.Grant) throws -> EventLoopFuture<Feide.AccessToken> {
        
        guard let basicAuth = config.basicAuth else {
            throw Abort(.internalServerError, reason: "Unable to encode secret")
        }
        
        let headers = HTTPHeaders(
            [
                ("Authorization", "Basic \(basicAuth)"),
                ("Content-Type", "application/x-www-form-urlencoded")
            ]
        )
        let body = Feide.AccessTokenRequest(
            code: grant.code,
            redirectURI: config.callbackUri,
            clientID: config.clientID
        )
        
        return client
            .post("\(config.authBaseUri)/oauth/token", headers: headers) { (req) in
                try req.content.encode(body, as: .urlEncodedForm)
            }
            .flatMapThrowing { try $0.content.decode(Feide.AccessToken.self) }
    }
    
    /// Fetches the user info associated with a token
    /// - Parameters:
    ///   - req: The HTTP requesting the user info
    ///   - token: The user token represented as a `AccessToken`
    /// - Returns: A future `UserInfo`
    public func userInfo(with token: Feide.AccessToken) -> EventLoopFuture<Feide.UserInfo> {
        
        let headers = HTTPHeaders(
            [
                ("Authorization", "Bearer \(token.accessToken)"),
                ("Accept", "application/json")
            ]
        )
        return client.get("\(config.authBaseUri)/openid/userinfo", headers: headers)
            .flatMapThrowing { try $0.content.decode(Feide.UserInfo.self) }
    }
    
    /// Ends the feide session
    /// - Parameter req: The HTTP request
    public func endSession(for req: Request) -> Response {
        req.redirect(to: "\(config.authBaseUri)/openid/endsession")
    }
    
    /// Returns all the subjects a user are regestrated for
    /// - Parameters:
    ///   - userToken: The users access token
    ///   - req: The request
    public func subjects(userToken: String) -> EventLoopFuture<[Feide.Subject]> {
        
        let headers = HTTPHeaders(
            [
                ("Authorization", "Bearer \(userToken)"),
                ("Accept", "application/json")
            ]
        )
        return client.get("\(config.apiBaseUri)/groups/me/groups", headers: headers)
            .flatMapThrowing {
                try $0.content.decode([Feide.Group].self)
                    .compactMap { group in
                        switch group {
                        case .subject(let subject): return subject
                        default: return nil
                        }
                    }
            }
    }
}

public struct FeideClientFactory {
    
    var make: ((Request) -> FeideClientRepresentable)?
    
    mutating func use(_ make: @escaping (Request) -> FeideClientRepresentable) {
        self.make = make
    }
}

extension Application {
    private struct FeideClientKey: StorageKey {
        typealias Value = FeideClientFactory
    }

    public var feideClient: FeideClientFactory {
        get { self.storage[FeideClientKey.self] ?? .init() }
        set { self.storage[FeideClientKey.self] = newValue }
    }
}

extension Request {
    public var feide: FeideClientRepresentable {
        self.application.feideClient.make!(self)
    }
}
