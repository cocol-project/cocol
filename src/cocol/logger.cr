module Cocol
  extend self

  def logger
    @@logger ||= Logger.new(
      STDOUT,
      level: Logger::DEBUG,
      progname: "#{Node.settings.ident}@#{Node.settings.host}:#{Node.settings.port}"
    )
  end
end
