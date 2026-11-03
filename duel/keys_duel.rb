# frozen_string_literal: true

require_relative 'duel_helper'

# KeyManager checks and rewrites every key before it's sent: the
# namespace, the 250-byte limit (a longer key is digested), and keys that
# must go base64-encoded. Multi-key operations map each key as sent back
# to the caller's.

duel 'keys: validate a short key' do
  once { @keys = Dalli::KeyManager.new({}) }
  @keys.validate_key('posts/42-20261102120000000000')
end

duel 'keys: validate a key with a namespace' do
  once { @keys = Dalli::KeyManager.new(namespace: 'myapp:production') }
  @keys.validate_key('posts/42-20261102120000000000')
end

duel 'keys: digest a key over 250 bytes' do
  once do
    @keys = Dalli::KeyManager.new({})
    @key = "views/posts/index/#{'q=ruby+memcached&page=2&' * 12}"
  end
  @keys.validate_key(@key)
end

duel 'keys: validate a key with spaces and non-ASCII characters' do
  once { @keys = Dalli::KeyManager.new({}) }
  @keys.validate_key('search/café crème brûlée')
end

duel 'keys: map 100 keys for a multi-get' do
  once do
    @keys = Dalli::KeyManager.new(namespace: 'myapp')
    @requested = keys_of(100)
  end
  @keys.caller_keys_by_wire_key(@requested)
end
