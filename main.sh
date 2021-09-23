#!/usr/bin/env bash
#
# Helper script.
#
set -eu -o pipefail
#set -x

if [ -e .env ]; then source ./.env; fi

#
# outputs
#
outputs_cache=.outputs.cache
if [ ! -e ${outputs_cache} ]; then
  make ${outputs_cache}
fi
function_name_main=$(jq -r .lambda_name_main.value < ${outputs_cache})
function_name_processor=$(jq -r .lambda_name_processor.value < ${outputs_cache})
function_name_subscribe=$(jq -r .lambda_name_subscribe.value < ${outputs_cache})
function_name_custom=$(jq -r .lambda_name_custom.value < ${outputs_cache})
function_name_efs=$(jq -r .lambda_name_efs.value < ${outputs_cache})
repository_name=$(jq -r .repository_name.value < ${outputs_cache})
repository_url=$(jq -r .repository_url.value < ${outputs_cache})
prefix=$(jq -r .prefix.value < ${outputs_cache})
bucket_url=s3://$(jq -r .bucket_name.value < ${outputs_cache})

function invoke-main() {
  _func_name=$(_func_name main) _invoke '{"name":"exec at '`date -u +%Y%m%dT%H%M%S`'"}'
}

function invoke-custom() {
  _func_name=$(_func_name custom) _invoke $*
}

function invoke-efs() {
  _func_name=$(_func_name efs) _invoke $*
}

function ls-s3() {
  aws s3 ls --recursive ${bucket_url}
}

function cp-s3() {
  aws s3 cp ${bucket_url}/$1 - 
}

function cp-s3-failed() {
  aws s3 cp ${bucket_url}/$1 - | jq .
}

function cleanup-s3() {
  aws s3 rm --recursive ${bucket_url}
}

function cleanup-log-groups() {
  for name in custom efs main processor ruby subscribe; do
    aws logs delete-log-group --log-group "/aws/lambda/${prefix}${name}"
  done
}

function docker-login() {
  aws ecr get-login-password | docker login --username AWS --password-stdin ${repository_url}
}

function push() {
  image_name=myfunc
  tag=${1-nodejs}
  dst=${repository_url}:${tag}
  docker tag ${image_name}:${tag} ${dst}
  docker push ${dst}
}

function update-func() {
  local fn=`_func_name ${1}`
  local _tag=${2-nodejs}
  aws lambda update-function-code \
    --function-name ${fn} \
    --image-uri ${repository_url}:${_tag} \
    | cat
  while [ `./main.sh get-func ${kind} | jq -r .Configuration.LastUpdateStatus` != "Successful" ] ; do
    printf .; sleep 1; done
  echo
}

function tail() { # <name>
  fn=`_func_name ${1-main}`
  aws logs tail --follow "/aws/lambda/${fn}"
}

function get-func() {
  fn=`_func_name ${1}`
  aws lambda get-function --function-name "${fn}"
}

function list-digests() {
  docker image ls | grep "${repository_name}" | awk '{print $3}' | parallel 'docker image inspect {1} | jq -r ".[]|[.RepoTags, .RepoDigests]"'
}

function desc-images() {
  aws ecr describe-images \
    --repository-name ${repository_name}
}

function del-image() {
  aws ecr batch-delete-image \
  --repository-name ${repository_name} \
  --image-ids imageDigest=${1}
}

function desc-dangling-images() {
  desc-images \
    | jq -r '.imageDetails[] | select(.imageTags | length == 0)'
}

function clean-dangling-images() {
  desc-dangling-images | jq -r '.imageDigest' | _batch-delete-image
}

function clean-all-images() {
  # Unknown parameter in imageIds[0]: "iamgeTag", must be one of: imageDigest, imageTag
  desc-images | jq -r .imageDetails[].imageDigest | _batch-delete-image
}

function _batch-delete-image() {
  parallel -j3 "aws ecr batch-delete-image --repository-name ${repository_name} --image-ids imageDigest={1}"
}

function invoke-after-update() {
  local _tag=${1-main}
  make build-nodejs && ./main.sh push && ./main.sh update-func $_tag && ./main.sh invoke-main `date +%H:%M`
}

function update-func-custom() {
  terraform apply --auto-approve \
    -target aws_lambda_function.custom \
    -target aws_lambda_layer_version.bash-runtime
}

function _func_name() {
  local kind=${1-main}
  case $kind in
    main)      echo ${function_name_main};;
    processor) echo ${function_name_processor};;
    subscribe) echo ${function_name_subscribe};;
    custom)    echo ${function_name_custom};;
    efs)       echo ${function_name_efs};;
  esac
}

function _invoke() { # [payload]
  fp=${1-""}
  if [ -e "$fp" ]; then
    payload=$(cat $fp)
  elif [ ! -z "$fp" ]; then
    payload=$fp
  else
    payload=$(cat)
  fi
  aws lambda invoke \
    --function-name ${_func_name} \
    --cli-binary-format raw-in-base64-out \
    --payload "${payload}" \
    output.json \
    && cat output.json
}

function help() {
cat<<EOF
Usage:
  main.sh [command] ...

EOF
  egrep "^function [^_]" $0 | sed -E 's/function +//;s/\(.*#//;s/\(.*//;s/^/\t/' | sort
  echo
  exit
}

cmd=${1-help}
if [ "${cmd}" == help ]; then help; fi

shift
${cmd} $*

