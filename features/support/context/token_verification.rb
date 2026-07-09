# frozen_string_literal: true

module Nonnative
  module Features
    module Context
      # Helpers for generating keys and tokens, and decoding/verifying generated tokens.
      module TokenVerification
        def ed25519_pem
          OpenSSL::PKey.new_raw_private_key('ED25519', SecureRandom.bytes(32)).private_to_pem
        end

        # Default generation options; scenarios override or extend them through the token table.
        TOKEN_DEFAULTS = { aud: 'GET /v1/things', sub: 'user-1' }.freeze

        # Generation options whose table values are Unix seconds and become Time objects.
        TOKEN_TIME_CLAIMS = %i[issued_at not_before expires_at].freeze

        def generate_token(kind, aud, sub)
          generate_token_with(kind, aud: aud, sub: sub)
        end

        def generate_token_with(kind, **)
          @kind = kind
          @token = Nonnative.token(kind: kind, issuer: 'iss', key: 'key-1', private_key: @private_key_path, expiration: 3600)
                            .generate(**TOKEN_DEFAULTS, **)
        end

        # Builds generate options from a Cucumber table so the generation step can be extended with
        # new claims by adding rows. Time-claim rows are Unix seconds and become Time objects.
        def token_options(table)
          table.rows_hash.each_with_object({}) do |(key, value), options|
            name = key.to_sym
            options[name] = TOKEN_TIME_CLAIMS.include?(name) ? Time.at(Integer(value)) : value
          end
        end

        # Returns the token's time claims normalised to Unix seconds, keyed by claim name. Absent
        # claims (for example ssh has no nbf) are omitted.
        def token_time_claims(kind, token, material)
          claims, = decoded_token(kind, token, material)

          %w[iat nbf exp].each_with_object({}) do |field, result|
            value = claims[field]
            result[field] = time_claim_seconds(kind, value) unless value.nil?
          end
        end

        def write_key_file(content)
          file = Tempfile.new(['ed25519', '.pem'])
          file.write(content)
          file.close
          # Keep a reference for the lifetime of the scenario; otherwise the Tempfile can be
          # garbage-collected and its finalizer unlinks the file before the key is read.
          (@key_files ||= []) << file

          file.path
        end

        def openssh_ed25519_key
          path = File.join(Dir.mktmpdir, 'id_ed25519')
          args = ['ssh-keygen', '-t', 'ed25519', '-N', '', '-C', '', '-f', path]
          raise 'ssh-keygen failed' unless system(*args, out: File::NULL, err: File::NULL)

          path
        end

        def time_claim_seconds(kind, value)
          case kind
          when 'paseto' then Time.iso8601(value).to_i
          when 'ssh' then value / 1_000_000_000
          else value
          end
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
          # Verify the signature but skip time-claim validation so deliberately not-yet-valid or
          # expired tokens (generated with time overrides) can be decoded and inspected.
          payload, header = JWT.decode(token, verify_key, true,
                                       algorithm: 'EdDSA', verify_expiration: false, verify_not_before: false)

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
