require 'json'
def lambda_handler(event:, context:)
  STDERR.puts "start handler on ruby runtime."
  cmds = event["commands"]
  if cmds then
    cmds.map {|e| `#{e}`}
  else
    "echo back #{event}"
  end
end