# frozen_string_literal: true

module Nonnative
  module Features
    module Context
      # Helpers for generating keys and tokens, and decoding/verifying generated tokens.
      module TokenVerification
        def ed25519_pem
          OpenSSL::PKey.new_raw_private_key('ED25519', SecureRandom.bytes(32)).private_to_pem
        end

        def generate_token(kind, aud, sub)
          @kind = kind
          @token = Nonnative.token(kind: kind, issuer: 'iss', key: 'key-1', private_key: @private_key_path, expiration: 3600)
                            .generate(aud: aud, sub: sub)
        end

        def write_key_file(content)
          file = Tempfile.new(['ed25519', '.pem'])
          file.write(content)
          file.close

          file.path
        end

        def openssh_ed25519_key
          path = File.join(Dir.mktmpdir, 'id_ed25519')
          args = ['ssh-keygen', '-t', 'ed25519', '-N', '', '-C', '', '-f', path]
          raise 'ssh-keygen failed' unless system(*args, out: File::NULL, err: File::NULL)

          path
        end

        def decoded_token(kind, token, material)
          case kind
          when 'jwt' then decoded_jwt(token, material)
          when 'paseto' then decoded_paseto(token, material)
          when 'ssh' then decoded_ssh(token, material)
          end
        end

        def decoded_jwt(token, pem)
          verify_key = Ed25519::SigningKey.new(OpenSSL::PKey.read(pem).raw_private_key).verify_key
          payload, header = JWT.decode(token, verify_key, true, algorithm: 'EdDSA')

          [payload, header['kid']]
        end

        def decoded_paseto(token, pem)
          require 'rbnacl'
          require 'paseto'

          # decode! verifies the Ed25519 signature but skips ruby-paseto's stricter claim/footer
          # validation (which would reject a non-PASERK kid that go-service accepts as plain JSON).
          result = Paseto::V4::Public.new(pem).decode!(token, implicit_assertion: '')

          [result.claims, result.footer['kid']]
        end

        def decoded_ssh(token, ssh_key)
          verify_key = Ed25519::SigningKey.new(SSHData::PrivateKey.parse_openssh(ssh_key).first.sk[0, 32]).verify_key
          raw_claims, raw_signature = token.split('.')
          claims = Base64.strict_decode64(raw_claims)
          raise 'invalid ssh token signature' unless verify_key.verify(Base64.strict_decode64(raw_signature), claims)

          parsed = JSON.parse(claims)
          [parsed, parsed['kid']]
        end
      end
    end
  end
end
