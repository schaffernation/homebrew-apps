#!/usr/bin/env ruby
# frozen_string_literal: true

# Copy each cask listed in casks.yaml from its app's repository into Casks/.
# An app keeps its cask at packaging/homebrew/NAME.rb.
#
# Usage: scripts/sync.rb [LIST]
#   LIST  The list to read. The default is casks.yaml in the tap.
#
# SYNC_RAW_BASE overrides where files are fetched from, for testing. The
# default is https://raw.githubusercontent.com.
#
# A cask that still has a placeholder checksum (all zeros) isn't released
# yet, so it's skipped, and any copy already in Casks/ stays as it is. A cask
# that can't be fetched, or whose name doesn't match its entry, fails the run
# without changing its copy. Casks no longer in the list are left alone;
# remove them by hand.

require "net/http"
require "uri"
require "yaml"

ROOT = File.expand_path("..", __dir__)
PLACEHOLDER = /^\s*sha256\s+"0{64}"/
NAME = /\A[a-z0-9][a-z0-9-]*\z/
REPO = %r{\A[\w.-]+/[\w.-]+\z}
RAW_BASE = ENV.fetch("SYNC_RAW_BASE", "https://raw.githubusercontent.com")

list = ARGV[0] || File.join(ROOT, "casks.yaml")
entries = YAML.safe_load(File.read(list)) || []
abort "#{list}: expected a list of casks" unless entries.is_a?(Array)

failed = false
entries.each do |entry|
  cask, repo = entry.values_at("cask", "repo")
  ref = entry["ref"] || "HEAD"
  unless cask.to_s.match?(NAME) && repo.to_s.match?(REPO)
    warn "#{list}: skipping an entry without a valid cask and repo: #{entry.inspect}"
    failed = true
    next
  end

  url = URI("#{RAW_BASE}/#{repo}/#{ref}/packaging/homebrew/#{cask}.rb")
  response = Net::HTTP.get_response(url)
  unless response.is_a?(Net::HTTPSuccess)
    warn "#{cask}: couldn't fetch #{url} (#{response.code})"
    failed = true
    next
  end
  body = response.body.force_encoding("UTF-8")

  unless body.match?(/^cask "#{Regexp.escape(cask)}" do$/)
    warn "#{cask}: #{url} doesn't declare cask \"#{cask}\""
    failed = true
    next
  end
  if body.match?(PLACEHOLDER)
    puts "#{cask}: not released yet (placeholder checksum), skipped"
    next
  end

  target = File.join(ROOT, "Casks", "#{cask}.rb")
  if File.exist?(target) && File.read(target) == body
    puts "#{cask}: up to date"
  else
    File.write(target, body)
    puts "#{cask}: updated from #{repo}"
  end
end

exit(failed ? 1 : 0)
