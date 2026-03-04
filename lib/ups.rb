# Feature detection for ups.dev platform
module Ups
  def self.pro?
    defined?(UpsPro::Engine)
  end
end