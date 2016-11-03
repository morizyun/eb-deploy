
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
eb init $AWS_APPLICATION
eb deploy $AWS_ENVIRONMENT --region $AWS_DEFAULT_REGION --staged --verbose
