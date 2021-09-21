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
bucket_url=s3://$(jq -r .bucket_name.value < ${outputs_cache})

function invoke() {
  local kind=${1-main}
  local _func_name
  case $kind in
    main) _func_name=${function_name_main};;
    efs)  _func_name=${function_name_efs};;
  esac

  aws lambda invoke \
    --function-name ${_func_name} \
    --cli-binary-format raw-in-base64-out \
    --payload '{"name":"exec at '`date -u +%Y%m%dT%H%M%S`'"}' \
    output.json \
    && cat output.json
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
  local kind=${1-main}
  local _tag=${2-nodejs}
  local _func_name
  case $kind in
    main)      _func_name=${function_name_main};;
    processor) _func_name=${function_name_processor};;
    subscribe) _func_name=${function_name_subscribe};;
  esac

  aws lambda update-function-code \
    --function-name ${_func_name} \
    --image-uri ${repository_url}:${_tag} \
    | cat
  while [ `./main.sh get-func ${kind} | jq -r .Configuration.LastUpdateStatus` != "Successful" ] ; do
    printf .; sleep 1; done
  echo
}

function tail() {
  kind=${1-main}
  case $kind in
    main)      aws logs tail --follow "/aws/lambda/${function_name_main}";;
    processor) aws logs tail --follow "/aws/lambda/${function_name_processor}";;
    subscribe) aws logs tail --follow "/aws/lambda/${function_name_subscribe}";;
    custom)    aws logs tail --follow "/aws/lambda/${function_name_custom}";;
    efs   )    aws logs tail --follow "/aws/lambda/${function_name_efs}";;
  esac
}

function get-func() {
  kind=${1-main}
  case $kind in
    main)      aws lambda get-function --function-name "${function_name_main}";;
    processor) aws lambda get-function --function-name "${function_name_processor}";;
    subscribe) aws lambda get-function --function-name "${function_name_subscribe}";;
    custom)    aws lambda get-function --function-name "${function_name_custom}";;
    efs)       aws lambda get-function --function-name "${function_name_efs}";;
  esac
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
  make build-nodejs && ./main.sh push && ./main.sh update-func $_tag && ./main.sh invoke `date +%H:%M`
}

function update-func-custom() {
  terraform apply --auto-approve \
    -target aws_lambda_function.custom \
    -target aws_lambda_layer_version.bash-runtime
}

function invoke-custom() {
  _func_name=${funciton_name_custom} _invoke $*
}

function invoke-efs() {
  _func_name=${function_name_efs} _invoke $*
}

function _invoke() {
  fp=${1-""}
  if [ -e "$fp" ]; then
    payload=$(cat $fp)
  else
    payload=$(cat)
  fi
  aws lambda invoke \
    --function-name ${_func_name} \
    --cli-binary-format raw-in-base64-out \
    --payload "${payload}" \
    output-custom.json \
    && cat output-custom.json
}

function help() {
cat<<EOF
Usage:
  main.sh [command] ...

EOF
  egrep "^function [^_]" $0 | sed -E 's/function +//;s/\(.*//;s/^/\t/' | sort
  echo
  exit
}

cmd=${1-help}
if [ "${cmd}" == help ]; then help; fi

shift
${cmd} $*

