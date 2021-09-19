#
# Assuming this is deployed with a layer on lambda.
#
#   stderr: print to CloudWatch Logs.
#   stdout: response of lambda invocation.
#
# How to debug:
#
#   $ source ./functions/bash/function.sh && handler '{}' 2>/dev/null
#
function handler() {
  EVENT_DATA=$1
  echo "EVENT_DATA: $EVENT_DATA" 1>&2  # to CloudWatch Logs
  
  # response
  echo "$EVENT_DATA" | jq -r '.commands[]' | while read cmd; do bash -c "${cmd}"; done

  echo
}

