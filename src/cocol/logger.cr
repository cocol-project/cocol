require "logger"

module Cocol
  extend self

  def logger
    @@logger ||= Logger.new(STDOUT, level: Logger::INFO)
  end
end
