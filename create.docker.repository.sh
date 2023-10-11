#!/bin/bash -x
# script to create docker repository

account_id=$1
repository_name=$2

function login_to_ecr() {
  local accid=$1
  echo -n "login in to ecr ($accid)..."
  aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin ${accid}.dkr.ecr.eu-west-1.amazonaws.com > /dev/null 2>&1
  if [ $? != 0 ] ; then
    echo "failed"
    exit -1
  else
    echo "done"
  fi
}

function create_repository(){
  local rep=$1
  echo -n "creating a repo ($rep)..."
  aws ecr create-repository --repository-name $rep > /dev/null 2>&1
  if [ $? != 0 ] ; then
    echo "failed"
    exit -1
  else
    echo "done"
  fi
}

function set_repository_policy(){
  local rep=$1
  local p=$2
  echo -n "setting repository permissions policy..."
  aws ecr set-repository-policy --repository-name $rep --policy-text file://policy.json > /dev/null 2>&1
  if [ $? != 0 ] ; then
    echo "failed"
    exit -1
  else
    echo "done"
  fi
}

function is_repository_exists(){
  local accid=$1
  local rep=$2
  local pol=$3
  echo -n "checking whether repository exists..."
  aws ecr describe-repositories --repository-names $rep > /dev/null 2>&1
  if [ $? == 0 ] ; then
    echo "exists"
  else
    echo "no. creating"
    create_repository $rep
  fi
  set_repository_policy $rep $pol
}

function get_repository_policy_from_secretsmanager(){
  echo -n "getting ecr repository policy from aws secrets manager..."
  aws secretsmanager get-secret-value --secret-id arn:aws:secretsmanager:eu-west-1:221581667315:secret:github-actions-GF251g  | jq -r ".SecretString" | jq -r ".ECR_REPOSITORY_POLICY" | jq -r > policy.json
  if [ $? != 0 ] ; then
    echo "failed"
  else
    echo "done"
  fi
}

login_to_ecr $account_id
get_repository_policy_from_secretsmanager
is_repository_exists $account_id $repository_name

