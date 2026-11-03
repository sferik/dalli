# frozen_string_literal: true

require_relative 'duel_helper'

# Single-key operations through Dalli::Client, end to end, against the
# worker's own memcached over a Unix socket: checking the arguments and
# the key, picking the server, marshalling the value, formatting the
# request, the round trip, and parsing the reply. Each leaves the cache as
# it found it, so every iteration does the same work.

duel 'client: get a small value' do
  once do
    @client = client
    @client.set('users/42', small_value)
  end
  @client.get('users/42')
end

duel 'client: get a miss' do
  once { @client = client }
  @client.get('users/404')
end

duel 'client: get a 32 KB value, compressed' do
  once do
    @client = client
    @client.set('fragments/42', text_of(32 * 1024))
  end
  @client.get('fragments/42')
end

duel 'client: get a 32 KB value with raw: true' do
  once do
    @client = client
    @options = { raw: true }
    @client.set('fragments/42', text_of(32 * 1024), 0, @options)
  end
  @client.get('fragments/42', @options)
end

duel 'client: set a small value' do
  once { @client = client }
  @client.set('users/42', small_value)
end

duel 'client: set a 32 KB value, compressed' do
  once do
    @client = client
    @value = text_of(32 * 1024)
  end
  @client.set('fragments/42', @value)
end

duel 'client: add a key that exists' do
  once do
    @client = client
    @client.set('users/42', small_value)
  end
  @client.add('users/42', small_value, 300)
end

duel 'client: delete a key that is missing' do
  once { @client = client }
  @client.delete('users/404')
end

duel 'client: fetch a hit' do
  once do
    @client = client
    @client.set('users/42', small_value)
  end
  @client.fetch('users/42') { small_value }
end

duel 'client: incr a counter' do
  once do
    @client = client
    @client.set('counters/views', '0', 0, raw: true)
  end
  @client.incr('counters/views', 1)
end

duel 'client: decr a counter, with an initial value' do
  once do
    @client = client
    @client.set('counters/stock', '1000000000', 0, raw: true)
  end
  @client.decr('counters/stock', 1, 300, 0)
end

duel 'client: get_with_metadata' do
  once do
    @client = client
    @client.set('users/42', small_value)
    @options = { return_hit_status: true, return_ttl_remaining: true }
  end
  @client.get_with_metadata('users/42', @options)
end
