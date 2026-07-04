import Foundation
import WebKit

// MARK: - GenerateIT Network

extension WebPoTokenService {
    func startGenerateIT(
        identifier: String,
        attemptID: String?,
        botguardResponse: String
    ) {
        AppLog.poToken("generate_it:native:start")
        guard let request = buildGenerateITRequest(
            botguardResponse: botguardResponse
        ) else {
            logAndFailGenerateIT(
                identifier: identifier,
                reason: "Invalid request"
            )
            return
        }
        transport.send(request, cancellationToken: nil) { [self] result in
            switch result {
            case .failure(let error):
                logAndFailGenerateIT(
                    identifier: identifier,
                    reason: error.localizedDescription
                )
            case .success(let response):
                handleGenerateITSuccess(
                    identifier: identifier,
                    attemptID: attemptID,
                    data: response.data,
                    status: response.status
                )
            }
        }
    }

    private func buildGenerateITRequest(
        botguardResponse: String
    ) -> HTTPRequest? {
        let urlStr =
            "https://jnn-pa.googleapis.com"
            + "/$rpc/google.internal.waa.v1.Waa"
            + "/GenerateIT"
        guard let url = URL(string: urlStr) else {
            return nil
        }
        let obj = [requestKey, botguardResponse]
        guard let body = try? JSONSerialization.data(
            withJSONObject: obj, options: []
        ) else {
            return nil
        }
        return HTTPRequest(
            method: .post,
            url: url,
            headers: generateITHeaders(),
            body: body,
            timeout: 8
        )
    }

    private func generateITHeaders() -> [String: String] {
        [
            HTTPHeader.contentType: "application/json+protobuf",
            HTTPHeader.xGoogApiKey: YouTubeCredentials.tvApiKey,
            HTTPHeader.xUserAgent: "grpc-web-javascript/0.1"
        ]
    }
}

// MARK: - GenerateIT Response

extension WebPoTokenService {
    private func handleGenerateITSuccess(
        identifier: String,
        attemptID: String?,
        data: Data?,
        status: Int
    ) {
        AppLog.poToken("generate_it:native:status \(status)")
        guard let data, !data.isEmpty else {
            logAndFailGenerateIT(
                identifier: identifier,
                reason: "No data"
            )
            return
        }
        processGenerateITData(
            data,
            identifier: identifier,
            attemptID: attemptID
        )
    }

    private func logAndFailGenerateIT(
        identifier: String,
        reason: String
    ) {
        AppLog.poToken(
            "generate_it:native:error \(reason)"
        )
        resolve(
            identifier: identifier,
            result: .failure(
                ServiceError
                    .generateITFailed(reason)
            )
        )
    }

    private func parseJSON(
        from data: Data,
        identifier: String
    ) -> Any? {
        if let json =
            try? JSONSerialization.jsonObject(
                with: data, options: []
            ) {
            return json
        }
        let text = String(
            data: data, encoding: .utf8
        ) ?? "<binary>"
        AppLog.poToken(
            "generate_it:native:raw "
            + "\(text.prefix(300))"
        )
        logAndFailGenerateIT(
            identifier: identifier,
            reason: "Invalid JSON"
        )
        return nil
    }

    private func processGenerateITData(
        _ data: Data,
        identifier: String,
        attemptID: String?
    ) {
        guard let json = parseJSON(
            from: data, identifier: identifier
        ) else {
            return
        }
        let token = extractIntegrityToken(
            from: json
        )
        let desc = String(describing: json)
        AppLog.poToken(
            "generate_it:native:shape "
            + "\(desc.prefix(500))"
        )
        guard let token, !token.isEmpty else {
            logAndFailGenerateIT(
                identifier: identifier,
                reason: "Missing integrity token"
            )
            return
        }
        AppLog.poToken("generate_it:native:ok")
        continueMint(
            identifier: identifier,
            attemptID: attemptID,
            integrityToken: token
        )
    }
}

// MARK: - Continue Mint

extension WebPoTokenService {
    func continueMint(
        identifier: String,
        attemptID: String?,
        integrityToken: String
    ) {
        guard let idLit =
            jsStringLiteral(identifier),
              let tkLit =
                  jsStringLiteral(integrityToken)
        else {
            resolve(
                identifier: identifier,
                result: .failure(
                    ServiceError.invalidMessage
                )
            )
            return
        }
        let attemptArg = attemptID.flatMap {
            jsStringLiteral($0)
        } ?? "undefined"
        let script = WebPoTokenScripts
            .continueMintScript(
                identifier: idLit,
                attemptID: attemptArg,
                integrityToken: tkLit
            )
        DispatchQueue.main.async {
            self.evaluateScript(
                script,
                identifier: identifier,
                attemptID: attemptID
            )
        }
    }
}

// MARK: - Integrity Token Extraction

extension WebPoTokenService {
    func extractIntegrityToken(
        from json: Any
    ) -> String? {
        if let string = json as? String,
           !string.isEmpty {
            return string
        }
        if let array = json as? [Any] {
            for value in array {
                let token = extractIntegrityToken(
                    from: value
                )
                if let token {
                    return token
                }
            }
        }
        return extractFromDict(json)
    }

    private func extractFromDict(
        _ json: Any
    ) -> String? {
        guard let dict = json as? [String: Any]
        else {
            return nil
        }
        if let token = dict["integrityToken"]
            as? String,
           !token.isEmpty {
            return token
        }
        for value in dict.values {
            let token = extractIntegrityToken(
                from: value
            )
            if let token {
                return token
            }
        }
        return nil
    }
}
