require 'timeout'
require File.dirname(__FILE__) + '/../vendor/plain_imap'

module Fetcher
  class Imap < Base

    PORT = 143

    protected

    # Additional Options:
    # * <tt>:authentication</tt> - authentication type to use, defaults to PLAIN
    # * <tt>:port</tt> - port to use (defaults to 143)
    # * <tt>:ssl</tt> - use SSL to connect
    # * <tt>:use_login</tt> - use LOGIN instead of AUTHENTICATE to connect (some IMAP servers, like GMail, do not support AUTHENTICATE)
    # * <tt>:processed_folder</tt> - if set to the name of a mailbox, messages will be moved to that mailbox instead of deleted after processing. The mailbox will be created if it does not exist.
    # * <tt>:error_folder:</tt> - the name of a mailbox where messages that cannot be processed (i.e., your receiver throws an exception) will be moved. Defaults to "bogus". The mailbox will be created if it does not exist.
    def initialize(options = {})
      @authentication = options.delete(:authentication) || "PLAIN"
      @port = options.delete(:port) || PORT
      @ssl = options.delete(:ssl)
      @use_login = options.delete(:use_login)
      @in_folder = options.delete(:in_folder) || "INBOX"
      @processed_folder = options.delete(:processed_folder)
      @error_folder = options.delete(:error_folder) || "bogus"
      @extra_args = options.delete(:extra_args) || []

      super(options)
    end

    # Open connection and login to server
    def establish_connection
      Timeout.timeout(15) do
        @connection = Net::IMAP.new(@server, @port, @ssl)
        if @use_login
          @connection.login(@username, @password)
        else
          @connection.authenticate(@authentication, @username, @password)
        end
      end
    end

    # Retrieve messages from server
    def get_messages
      @connection.select(@in_folder)
      @connection.uid_search(["ALL"]).each do |uid|
        msg = @connection.uid_fetch(uid, "RFC822").first.attr["RFC822"]
        begin
          process_message(msg)
          add_to_processed_folder(uid) if @processed_folder
        rescue => e
          # NOTE: the magic
          $stderr.puts e.message
          Rails.logger.fatal e.message
          Rails.logger.fatal e.backtrace.join("\n")

          handle_bogus_message(msg)
        end
        # Mark message as deleted
        @connection.uid_store(uid, "+FLAGS", [:Seen, :Deleted])
      end
    end

    # Send message to receiver object. Patched to send extra args as well
    def process_message(message)
      if @extra_args.present?
        @receiver.receive(message, *@extra_args)
      else
        @receiver.receive(message)
      end
    end

    # Store the message for inspection if the receiver errors
    def handle_bogus_message(message)
      create_mailbox(@error_folder)
      @connection.append(@error_folder, message)
    end

    # Delete messages and log out
    def close_connection
      @connection.expunge
      @connection.logout
      begin
        @connection.disconnect unless @connection.disconnected?
      rescue
        Rails.logger.info("Fetcher: Remote closed connection before I could disconnect.")
      end
    end

    def add_to_processed_folder(uid)
      create_mailbox(@processed_folder)
      @connection.uid_copy(uid, @processed_folder)
    end

    def create_mailbox(mailbox)
      unless @connection.list("", mailbox)
        @connection.create(mailbox)
      end
    end
  end
end
