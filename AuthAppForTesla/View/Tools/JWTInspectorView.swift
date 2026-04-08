//
//  JWTInspectorView.swift
//  AuthAppForTesla
//
//  A general-purpose JWT inspector. Decodes any pasted token (or the
//  currently stored Owners/Fleet token) into a structured view of its
//  header and payload claims. Signature verification is intentionally
//  not performed — this is a developer/diagnostic tool only.
//

import SwiftUI
import UniformTypeIdentifiers

struct JWTInspectorView: View {
    @Bindable var model: AuthViewModel
    @State private var input: String

    init(model: AuthViewModel, initialInput: String = "") {
        self.model = model
        _input = State(initialValue: initialInput)
    }

    private var decoded: DecodedJWT? {
        JWTDecoder.decode(input)
    }

    var body: some View {
        Form {
            Section("Token") {
                JWTInputField(text: $input)
                JWTInspectorActions(input: $input, model: model)
            }

            if let decoded {
                JWTStatusSection(decoded: decoded)
                JWTClaimsSection(decoded: decoded)
                JWTRawSegmentSection(title: "Header", json: decoded.header)
                JWTRawSegmentSection(title: "Payload", json: decoded.payload)
                if let signature = decoded.signature, !signature.isEmpty {
                    Section("Signature") {
                        Text(signature)
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                    }
                }
            } else if !input.isEmpty {
                Section {
                    Label("This doesn't look like a valid JWT.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("JWT Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct JWTInputField: View {
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.footnote.monospaced())
                .frame(minHeight: 90)
                .accessibilityIdentifier("jwtInspectorInput")
            if text.isEmpty {
                Text("Paste a JWT here, or pick one from your stored tokens below.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    .padding(.leading, 5)
                    .allowsHitTesting(false)
            }
        }
    }
}

private struct JWTInspectorActions: View {
    @Binding var input: String
    @Bindable var model: AuthViewModel

    var body: some View {
        HStack {
            Button("Paste", systemImage: "doc.on.clipboard") {
                if let pasted = UIPasteboard.general.string {
                    input = pasted
                }
            }
            .buttonStyle(.bordered)

            Spacer()

            Menu("Use Stored Token", systemImage: "key.horizontal") {
                if let access = model.tokenV3?.access_token, !access.isEmpty {
                    Button("Owners API – Access") { input = access }
                }
                if let refresh = model.tokenV3?.refresh_token, !refresh.isEmpty {
                    Button("Owners API – Refresh") { input = refresh }
                }
                if let access = model.tokenV4?.access_token, !access.isEmpty {
                    Button("Fleet API – Access") { input = access }
                }
                if let refresh = model.tokenV4?.refresh_token, !refresh.isEmpty {
                    Button("Fleet API – Refresh") { input = refresh }
                }
            }
            .disabled(model.tokenV3 == nil && model.tokenV4 == nil)
        }
    }
}

private struct JWTStatusSection: View {
    let decoded: DecodedJWT

    var body: some View {
        Section("Status") {
            if let expiresAt = decoded.expiresAt {
                let isExpired = expiresAt <= Date()
                LabeledContent("Status") {
                    Label(
                        isExpired ? "Expired" : "Valid",
                        systemImage: isExpired ? "xmark.circle.fill" : "checkmark.seal.fill"
                    )
                    .foregroundStyle(isExpired ? Color("TeslaRed") : .green)
                }
                LabeledContent(isExpired ? "Expired" : "Expires") {
                    Text(expiresAt, style: .relative)
                }
                LabeledContent("Expiry Date") {
                    Text(expiresAt.formatted(date: .abbreviated, time: .shortened))
                }
            }
            if let issuedAt = decoded.issuedAt {
                LabeledContent("Issued") {
                    Text(issuedAt.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
    }
}

private struct JWTClaimsSection: View {
    let decoded: DecodedJWT

    var body: some View {
        Section("Claims") {
            if let issuer = decoded.issuer {
                LabeledContent("Issuer", value: issuer)
            }
            if let subject = decoded.subject {
                LabeledContent("Subject", value: subject)
            }
            if let azp = decoded.authorizedParty {
                LabeledContent("Authorized Party", value: azp)
            }
            if !decoded.audiences.isEmpty {
                DisclosureGroup("Audiences (\(decoded.audiences.count))") {
                    ForEach(decoded.audiences, id: \.self) { aud in
                        Text(aud).font(.footnote.monospaced())
                    }
                }
            }
            if !decoded.scopes.isEmpty {
                DisclosureGroup("Scopes (\(decoded.scopes.count))") {
                    ForEach(decoded.scopes, id: \.self) { scope in
                        Text(scope).font(.footnote.monospaced())
                    }
                }
            }
        }
    }
}

private struct JWTRawSegmentSection: View {
    let title: String
    let json: String?

    var body: some View {
        if let json {
            Section(title) {
                Text(json)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
                Button("Copy", systemImage: "doc.on.doc") {
                    UIPasteboard.general.setItems(
                        [[UTType.utf8PlainText.identifier: json]],
                        options: [.expirationDate: Date(timeIntervalSinceNow: 3600)]
                    )
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview("Empty") {
    NavigationStack {
        JWTInspectorView(model: AuthViewModel())
    }
}

#Preview("With Stored Tokens") {
    NavigationStack {
        JWTInspectorView(model: PreviewModelFactory.populatedModel())
    }
}

#Preview("Decoded") {
    NavigationStack {
        JWTInspectorView(
            model: PreviewModelFactory.populatedModel(),
            initialInput: PreviewModelFactory.sampleAccessToken
        )
    }
}
