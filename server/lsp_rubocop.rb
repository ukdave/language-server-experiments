#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "open3"

# A Ruby language server that runs Rubocop whenever a file
# is saved and reports any offenses back to the editor.
class LspRubocop
  def initialize(io_in, io_out)
    @in = io_in
    @out = io_out
  end

  def call
    loop do
      message = read_message
      break unless message

      handle(message)
    end
  end

  def read_message
    buffer = @in.gets("\r\n\r\n")
    content_length = buffer.match(/Content-Length: (\d+)/i)&.[](1)&.to_i
    return nil unless content_length

    message = @in.read(content_length)
    JSON.parse(message)
  end

  def write_message(response)
    str = JSON.dump(response.merge("jsonrpc" => "2.0"))
    @out.write("Content-Length: #{str.bytesize}\r\n")
    @out.write("\r\n")
    @out.write(str)
    @out.flush
  end

  def handle(message)
    case message["method"]
    when "initialize"
      handle_initialize(message)
    when "textDocument/didSave"
      handle_did_save(message)
    end
  end

  def handle_initialize(message)
    result = {
      "capabilities" => {
        "textDocumentSync" => { "save" => true }
      }
    }
    write_message({ "id" => message["id"], "result" => result })
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def handle_did_save(message)
    doc = message.dig("params", "textDocument")
    file = doc["uri"].delete_prefix("file://")

    stdout_str, _status = Open3.capture2("bundle", "exec", "rubocop", "--format", "json", file)
    offenses = Array(JSON.parse(stdout_str).dig("files", 0, "offenses"))
    diagnostics = offenses.map do |offense|
      location = offense["location"]
      {
        "range" => {
          "start" => { "character" => location["start_column"] - 1, "line" => location["start_line"] - 1 },
          "end" => { "character" => location["last_column"], "line" => location["last_line"] - 1 }
        },
        "message" => offense["message"],
        "severity" => 2
      }
    end

    params = { "uri" => doc["uri"], "diagnostics" => diagnostics }
    write_message({ "method" => "textDocument/publishDiagnostics", "params" => params })
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end

LspRubocop.new($stdin, $stdout).call
