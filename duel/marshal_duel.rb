# frozen_string_literal: true

require_relative 'duel_helper'

# The value pipeline on its own, as every write and read runs it:
# ValueMarshaller serializes a value, compresses it when it's at least
# compression_min_size (4 KB), and checks it against value_max_bytes, then
# undoes that from the flags a reply carries. No server is needed.

duel 'marshal: store a small Hash with Marshal' do
  once do
    @marshaller = Dalli::Protocol::ValueMarshaller.new(serializer: Marshal)
    @value = small_value
  end
  @marshaller.store('users/42', @value)
end

duel 'marshal: retrieve a small Hash with Marshal' do
  once do
    @marshaller = Dalli::Protocol::ValueMarshaller.new(serializer: Marshal)
    @stored, @flags = @marshaller.store('users/42', small_value)
  end
  @marshaller.retrieve(@stored, @flags)
end

duel 'marshal: store a small Hash with JSON' do
  once do
    @marshaller = Dalli::Protocol::ValueMarshaller.new(serializer: Dalli::JSONSerializer)
    @value = small_value
  end
  @marshaller.store('users/42', @value)
end

duel 'marshal: store a String with string_fastpath' do
  once do
    @marshaller = Dalli::Protocol::ValueMarshaller.new(serializer: Marshal, string_fastpath: true)
    @value = text_of(512)
  end
  @marshaller.store('fragments/42', @value)
end

# Just under the threshold, so it's checked for compression and isn't.
duel 'marshal: store a 4 KB String, just under the compression threshold' do
  once do
    @marshaller = Dalli::Protocol::ValueMarshaller.new(serializer: Marshal)
    @value = text_of(4000)
  end
  @marshaller.store('fragments/42', @value)
end

duel 'marshal: store and compress a 32 KB String' do
  once do
    @marshaller = Dalli::Protocol::ValueMarshaller.new(serializer: Marshal)
    @value = text_of(32 * 1024)
  end
  @marshaller.store('fragments/42', @value)
end

duel 'marshal: retrieve and decompress a 32 KB String' do
  once do
    @marshaller = Dalli::Protocol::ValueMarshaller.new(serializer: Marshal)
    @stored, @flags = @marshaller.store('fragments/42', text_of(32 * 1024))
  end
  @marshaller.retrieve(@stored, @flags)
end
