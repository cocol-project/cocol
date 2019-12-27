module Cocol
  extend self

  def logger
    @@logger ||= Logger.new(
      STDOUT,
      level: Logger::DEBUG,
      progname: Node.settings.port.to_s
    )
  end
end
