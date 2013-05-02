require 'rails/generators'

module Fetcher
  class DaemonGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)
      
    def create_fetcher_daemon
      copy_file('daemon.rb', "lib/daemon.rb")
      template('config.yml', File.join('config', "#{file_name}.yml"))
      template('daemon', File.join('script', "#{file_name}_fetcher"))
      chmod(File.join("script", "#{file_name}_fetcher"), 0755)
    end
  end
end
