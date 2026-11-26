# Accepted design for tokens

Part of the [accepted-design index](../accepted-design.md).

## Signing key provisioning

The `private_key:` argument takes the path to a provisioned PKCS#8 Ed25519 PEM
file. `Nonnative::Ed25519Key` reads it with `File.read`. The file-based interface
lets callers manage key storage and access through their provisioning setup.
Callers that already hold the key bytes can write them to a file before signing,
as the Cucumber support code does. Revisit an in-memory `private_key_pem:`
argument or `Nonnative::Ed25519Key.from_pem` only when the task explicitly changes
how signing keys are supplied.

[Key loader](../../../lib/nonnative/ed25519_key.rb) · [Token test support](../../../features/support/context/token_verification.rb)
