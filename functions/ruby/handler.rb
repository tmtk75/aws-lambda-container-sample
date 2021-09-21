require 'json'
def lambda_handler(event:, context:)
  STDERR.puts "start"
  event["commands"].map {|e| `#{e}`}
end