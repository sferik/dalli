# frozen_string_literal: true

require_relative 'duel_helper'

# Operations on many keys, as a page that renders a list does. With one
# server, Dalli takes a fast path of its own, and with more, the
# Pipelined* classes group the keys by server and read the replies as
# they come. The three servers here are links to the worker's one
# memcached (see client_of_three), each a connection of its own.

duel 'multi: get_multi 100 keys' do
  once do
    @client = client
    @keys = keys_of(100)
    @keys.each { |key| @client.set(key, small_value) }
  end
  @client.get_multi(@keys)
end

duel 'multi: get_multi 100 keys, half of them misses' do
  once do
    @client = client
    @keys = keys_of(100)
    @keys.each_slice(2) { |key, _| @client.set(key, small_value) }
  end
  @client.get_multi(@keys)
end

duel 'multi: set_multi 100 keys' do
  once do
    @client = client
    @values = keys_of(100).to_h { |key| [key, small_value] }
  end
  @client.set_multi(@values, 300)
end

duel 'multi: set 100 keys in a quiet block' do
  once do
    @client = client
    @values = keys_of(100).to_h { |key| [key, small_value] }
  end
  @client.quiet { @values.each { |key, value| @client.set(key, value, 300) } }
end

duel 'multi: delete_multi 100 missing keys' do
  once do
    @client = client
    @keys = keys_of(100)
  end
  @client.delete_multi(@keys)
end

duel 'multi: get_multi 100 keys over 3 servers' do
  once do
    @client = client_of_three
    @keys = keys_of(100)
    @keys.each { |key| @client.set(key, small_value) }
  end
  @client.get_multi(@keys)
end

duel 'multi: set_multi 100 keys over 3 servers' do
  once do
    @client = client_of_three
    @values = keys_of(100).to_h { |key| [key, small_value] }
  end
  @client.set_multi(@values, 300)
end

duel 'multi: delete_multi 100 missing keys over 3 servers' do
  once do
    @client = client_of_three
    @keys = keys_of(100)
  end
  @client.delete_multi(@keys)
end
