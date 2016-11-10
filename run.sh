
if [ ! -n "$WERCKER_EB_DEPLOY_ACCESS_KEY" ]; then
  error 'Please specify access_key'
  exit 1
fi

if [ ! -n "$WERCKER_EB_DEPLOY_SECRET_KEY" ]; then
  error 'Please specify secret_key'
  exit 1
fi

if [ ! -n "$WERCKER_EB_DEPLOY_APP_NAME" ]; then
  error 'Please specify app_name'
  exit 1
fi

if [ ! -n "$WERCKER_EB_DEPLOY_ENV_NAME" ]; then
  error 'Please specify env_name'
  exit 1
fi

if [ ! -n "$WERCKER_EB_DEPLOY_REGION" ]; then
  error 'Please specify region'
  exit 1
fi

if [ ! -n "$WERCKER_EB_DEPLOY_PLATFORM" ]; then
  export WERCKER_EB_DEPLOY_PLATFORM='64bit Amazon Linux 2016.03 v2.1.6 running Ruby 2.3 (Puma)'
fi

info 'Installing pip...'
sudo apt-get update
sudo apt-get install -y python-pip libpython-all-dev zip

info 'Installing the AWS EB CLI...';
pip install --upgrade --user awsebcli
export PATH=~/.local/bin:$PATH
eb --version

export AWS_ACCESS_KEY_ID=$WERCKER_EB_DEPLOY_ACCESS_KEY
export AWS_SECRET_ACCESS_KEY=$WERCKER_EB_DEPLOY_SECRET_KEY
export AWS_APPLICATION=$WERCKER_EB_DEPLOY_APP_NAME
export AWS_ENVIRONMENT=$WERCKER_EB_DEPLOY_ENV_NAME
export AWS_DEFAULT_REGION=$WERCKER_EB_DEPLOY_REGION
export AWS_CONFIG_FILE=$WERCKER_ROOT/.aws/config

git add .

mkdir -p "$WERCKER_SOURCE_DIR/.elasticbeanstalk/"
cat > $WERCKER_SOURCE_DIR/.elasticbeanstalk/config.yml << EOF
branch-defaults:
  $WERCKER_GIT_BRANCH:
    environment: $WERCKER_EBDEPLOY_ENVIRONMENT
global:
  application_name: $WERCKER_EBDEPLOY_APPLICATION
  default_region: $WERCKER_EBDEPLOY_REGION
  profile: null
  sc: git
branch-defaults:
  ebextensions:
    environment: $WERCKER_EBDEPLOY_ENVIRONMENT
  master:
    environment: $WERCKER_EBDEPLOY_ENVIRONMENT
  seo_tags:
    environment: $WERCKER_EBDEPLOY_ENVIRONMENT
global:
  application_name: $WERCKER_EBDEPLOY_APPLICATION
  default_ec2_keyname: aws-eb.$WERCKER_EBDEPLOY_APPLICATION
  default_platform: $WERCKER_EB_DEPLOY_PLATFORM
  default_region: $WERCKER_EBDEPLOY_REGION
  profile: eb-cli
  sc: git
EOF
exec 3>&1

for((i=0; i < 10; i++)); do
  out=$(eb deploy $WERCKER_EBDEPLOY_ENVIRONMENT --timeout 9999 --nohang | tee >(cat - >&3))
  if [[ "$out" == *"invalid state"* ]]; then
    echo "Retrying in 10 seconds..."
	  sleep 10
  else
	  break
  fi
done