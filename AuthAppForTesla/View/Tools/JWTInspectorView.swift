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
        IconBackgroundView {
            ScrollView {
                VStack(spacing: 16) {
                    JWTHeaderCard()

                    JWTInputCard(input: $input, model: model)

                    if let decoded {
                        JWTStatusCard(decoded: decoded)
                        JWTClaimsCard(decoded: decoded)
                        if let header = decoded.header {
                            JWTRawSegmentCard(title: "Header", json: header)
                        }
                        if let payload = decoded.payload {
                            JWTRawSegmentCard(title: "Payload", json: payload)
                        }
                        if let signature = decoded.signature, !signature.isEmpty {
                            JWTSignatureCard(signature: signature)
                        }
                    } else if !input.isEmpty {
                        JWTInvalidCard()
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("JWT Inspector")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Cards

private struct JWTHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("JWT Inspector")
                .font(.title)
                .bold()
            Text("Decode any JWT into its header, payload, scopes, and expiry. Signatures are not verified.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .glassCard()
    }
}

private struct JWTInputCard: View {
    @Binding var input: String
    @Bindable var model: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Token")
                .font(.title2)
                .bold()
            JWTInputField(text: $input)
            JWTInspectorActions(input: $input, model: model)
        }
        .glassCard()
    }
}

private struct JWTInputField: View {
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.footnote.monospaced())
                .scrollContentBackground(.hidden)
                .frame(minHeight: 110)
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
        .padding(10)
        .glassEffect(.clear, in: .rect(cornerRadius: 16))
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
            .buttonStyle(.glass(.regular))

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
            .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
            .foregroundStyle(.white)
            .disabled(model.tokenV3 == nil && model.tokenV4 == nil)
        }
    }
}

private struct JWTStatusCard: View {
    let decoded: DecodedJWT

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Status")
                .font(.title2)
                .bold()
            if let expiresAt = decoded.expiresAt {
                let isExpired = expiresAt <= Date()
                HStack(spacing: 6) {
                    Image(systemName: isExpired ? "xmark.octagon.fill" : "checkmark.seal.fill")
                        .foregroundStyle(isExpired ? Color("TeslaRed") : .green)
                    Text(isExpired ? "Expired" : "Valid")
                        .font(.headline)
                        .foregroundStyle(isExpired ? Color("TeslaRed") : .green)
                }
                LabeledRow(label: isExpired ? "Expired" : "Expires") {
                    Text(expiresAt, style: .relative)
                }
                LabeledRow(label: "Expiry Date") {
                    Text(expiresAt.formatted(date: .abbreviated, time: .shortened))
                }
            }
            if let issuedAt = decoded.issuedAt {
                LabeledRow(label: "Issued") {
                    Text(issuedAt.formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
        .glassCard()
    }
}

private struct JWTClaimsCard: View {
    let decoded: DecodedJWT
    @State private var audiencesExpanded = false
    @State private var scopesExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Claims")
                .font(.title2)
                .bold()
            if let issuer = decoded.issuer {
                LabeledRow(label: "Issuer") {
                    Text(issuer).multilineTextAlignment(.trailing)
                }
            }
            if let subject = decoded.subject {
                LabeledRow(label: "Subject") { Text(subject) }
            }
            if let azp = decoded.authorizedParty {
                LabeledRow(label: "Authorized Party") { Text(azp) }
            }
            if !decoded.audiences.isEmpty {
                DisclosureGroup(isExpanded: $audiencesExpanded) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(decoded.audiences, id: \.self) { aud in
                            Text(aud).font(.footnote.monospaced()).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    Text("Audiences (\(decoded.audiences.count))")
                        .font(.subheadline)
                }
                .tint(Color("TeslaRed"))
            }
            if !decoded.scopes.isEmpty {
                DisclosureGroup(isExpanded: $scopesExpanded) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(decoded.scopes, id: \.self) { scope in
                            Text(scope).font(.footnote.monospaced()).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    Text("Scopes (\(decoded.scopes.count))")
                        .font(.subheadline)
                }
                .tint(Color("TeslaRed"))
            }
        }
        .glassCard()
    }
}

private struct JWTRawSegmentCard: View {
    let title: String
    let json: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Copy", systemImage: "doc.on.doc") {
                    UIPasteboard.general.setItems(
                        [[UTType.utf8PlainText.identifier: json]],
                        options: [.expirationDate: Date(timeIntervalSinceNow: 3600)]
                    )
                }
                .buttonStyle(.glass(.regular))
                .labelStyle(.iconOnly)
            }
            Text(json)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .glassEffect(.clear, in: .rect(cornerRadius: 16))
        }
        .glassCard()
    }
}

private struct JWTSignatureCard: View {
    let signature: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Signature")
                .font(.title2)
                .bold()
            Text(signature)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .glassEffect(.clear, in: .rect(cornerRadius: 16))
        }
        .glassCard()
    }
}

private struct JWTInvalidCard: View {
    var body: some View {
        Label("This doesn't look like a valid JWT.", systemImage: "exclamationmark.triangle.fill")
            .font(.subheadline)
            .foregroundStyle(Color("TeslaRed"))
            .glassCard()
    }
}

/// A horizontal label/value row that mimics the look of `LabeledContent`
/// in a `Form`, but works on a plain `VStack` inside a glass card.
private struct LabeledRow<Value: View>: View {
    let label: String
    @ViewBuilder var value: Value

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            value
                .font(.subheadline)
                .foregroundStyle(.primary)
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
