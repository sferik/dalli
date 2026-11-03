# frozen_string_literal: true

require 'fileutils'
require 'logger'
require 'tmpdir'

# Dalli warns once that Marshal is the default serializer, and logs a
# server's ups and downs. Neither belongs in a benchmark's output.
Dalli.logger.level = Logger::ERROR

# A value about the size of a cached record or fragment: well under the
# compression threshold (4 KB), so it's only serialized.
def small_value
  { id: 42, name: 'Jane Doe', email: 'jane@example.com', roles: %w[admin editor], active: true, score: 97.5 }
end

# Text of this many bytes, the same every time. It compresses well, as
# cached HTML and JSON do.
def text_of(bytes)
  line = "<li class=\"item\"><a href=\"/posts/42\">The quick brown fox jumps over the lazy dog</a></li>\n"
  (line * ((bytes / line.bytesize) + 1)).byteslice(0, bytes)
end

# Keys like an app's: a model, an id and a version.
def keys_of(count, prefix = 'posts')
  Array.new(count) { |i| "#{prefix}/#{i}-20261102120000000000" }
end

# A client of the worker's own memcached (see c.use :memcached in
# .duel.rb), over a Unix socket. Its server is flushed first, so every
# benchmark starts from an empty cache.
def client(**options)
  Duel::Memcached.flush
  Dalli::Client.new(Duel::Memcached.servers, { serializer: Marshal }.merge(options))
end

# A client of three servers, each a link to the worker's one memcached,
# so the keys are spread over three connections and the multi-key
# operations take their pipelined path, without starting more servers.
def client_of_three(**options)
  Duel::Memcached.flush
  dir = Dir.mktmpdir('dalli-duel')
  at_exit { FileUtils.rm_rf(dir) }
  servers = Array.new(3) do |i|
    File.join(dir, "memcached-#{i}.sock").tap { |link| File.symlink(Duel::Memcached.servers, link) }
  end
  Dalli::Client.new(servers, { serializer: Marshal }.merge(options))
end

# Server names, as an app would give them for a ring: a ring is built
# from these alone, and nothing connects to them.
def server_names(count)
  Array.new(count) { |i| "cache-#{i + 1}.internal.example.com:11211" }
end
