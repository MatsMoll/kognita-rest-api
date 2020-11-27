//
//  HTTPSRedirectMiddleware.swift
//  KognitaAPI
//
//  Created by Mats Mollestad on 27/11/2020.
//

import Vapor

class HTTPSRedirectMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard request.application.environment == Environment.production else {
            return next.respond(to: request)
        }

        let proto = request.headers.first(name: "X-Forwarded-Proto")
            ?? request.url.scheme
            ?? "http"

        guard proto == "https" else {
            guard let host = request.headers.first(name: .host) else {
                return request.eventLoop.future(error: Abort(.badRequest))
            }

            let httpsURL = "https://" + host + request.url.string
            return request.eventLoop.future(request.redirect(to: httpsURL, type: .permanent))
        }

        return next.respond(to: request)
            .map { resp in
                resp.headers.add(
                    name: "Strict-Transport-Security",
                    value: "max-age=31536000; includeSubDomains; preload")
                return resp
            }
    }
}
