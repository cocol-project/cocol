class CLI::Logger
  def self.info(message : String)
    puts "\33[2K\r #{message}"
    print "> "
  end
end
