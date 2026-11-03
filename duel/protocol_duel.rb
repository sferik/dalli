# frozen_string_literal: true

require_relative 'duel_helper'

# The meta protocol's requests and replies, without a socket:
# RequestFormatter builds what's written, and ResponseProcessor parses
# what memcached answers, here from fixed replies in memory (a Reply).
# The client benchmarks time these too, with a round trip besides.

# Fixed bytes, read as a connection reads them: a line at a time, or a
# number of bytes. Each request starts the same reply again.
class Reply
  def initialize(bytes)
    @bytes = bytes.b.freeze
    @offset = 0
  end

  def rewind
    @offset = 0
    self
  end

  def read_line
    stop = @bytes.byteindex("\r\n", @offset) + 2
    line = @bytes.byteslice(@offset, stop - @offset)
    @offset = stop
    line
  end

  def read(count)
    data = @bytes.byteslice(@offset, count)
    @offset += count
    data
  end
end

duel 'protocol: format a get' do
  Dalli::Protocol::Meta::RequestFormatter.plain_meta_get('posts/42-20261102120000000000', false)
end

duel 'protocol: format a set with a TTL' do
  Dalli::Protocol::Meta::RequestFormatter.plain_meta_set('posts/42-20261102120000000000', 512, 1, 300)
end

duel 'protocol: format a multi-get of 100 keys' do
  once { @keys = keys_of(100) }
  Dalli::Protocol::Meta::RequestFormatter.multi_meta_get(@keys)
end

duel 'protocol: format a multi-set of 100 values' do
  once do
    marshaller = Dalli::Protocol::ValueMarshaller.new(serializer: Marshal)
    @entries = keys_of(100).map { |key| [key, marshaller.store(key, small_value)] }
  end
  Dalli::Protocol::Meta::RequestFormatter.multi_meta_set(@entries, ttl: 300)
end

duel 'protocol: parse a get hit' do
  once do
    @value, flags = Dalli::Protocol::ValueMarshaller.new(serializer: Marshal).store('users/42', small_value)
    @reply = Reply.new("VA #{@value.bytesize} f#{flags}\r\n#{@value}\r\n")
    @processor = Dalli::Protocol::Meta::ResponseProcessor.new(@reply,
                                                              Dalli::Protocol::ValueMarshaller.new(serializer: Marshal))
  end
  @reply.rewind
  @processor.meta_get_with_value
end

# The pipelined get's replies, from a buffer: 100 hits, then the noop's MN.
duel 'protocol: parse 100 pipelined get replies' do
  once do
    marshaller = Dalli::Protocol::ValueMarshaller.new(serializer: Marshal)
    @buffer = keys_of(100).map do |key|
      value, flags = marshaller.store(key, small_value)
      "VA #{value.bytesize} f#{flags} k#{key} s#{value.bytesize}\r\n#{value}\r\n"
    end.join.b << "MN\r\n"
    @processor = Dalli::Protocol::Meta::ResponseProcessor.new(nil, marshaller)
  end
  offset = 0
  loop do
    _status, _cas, key, _value, size = @processor.getk_response_from_buffer(@buffer, offset)
    break unless key

    offset += size
  end
  offset
end
