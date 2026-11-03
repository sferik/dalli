# frozen_string_literal: true

require_relative 'duel_helper'

# The consistent hash ring that picks each key's server, for a client of
# more than one server. The servers are names that nothing connects to:
# the ring asks each whether it's alive, which would connect, so they
# answer yes at once, and only the ring's own work is timed.

duel 'ring: pick the server for a key, of 8' do
  once do
    @ring = Dalli::Ring.new(server_names(8), failover: false)
    @ring.servers.each { |server| server.define_singleton_method(:alive?) { true } }
  end
  @ring.server_for_key('posts/42-20261102120000000000')
end

duel 'ring: group 100 keys by server, of 8' do
  once do
    @ring = Dalli::Ring.new(server_names(8), failover: false)
    @ring.servers.each { |server| server.define_singleton_method(:alive?) { true } }
    @keys = keys_of(100)
  end
  @ring.keys_grouped_by_server(@keys)
end
