export UNIXTIME=`date +%s`

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

if [ ! -n "$WERCKER_EB_DEPLOY_S3_BUCKET" ]; then
  error 'Please specify s3 bucket'
  exit 1
fi

if [ ! -n "$WERCKER_EB_DEPLOY_REGION" ]; then
  info 'set default region as ap-northeast-1'
  export WERCKER_EB_DEPLOY_REGION="ap-northeast-1"
fi

info 'Installing pip ...'
sudo apt-get update
sudo apt-get install -y python-pip libpython-all-dev zip

info 'Installing the AWS CLI ...';
pip install awscli;
export PATH=~/.local/bin:$PATH
aws --version

info 'export set default values for AWS CLI tool ...';
export AMAZON_ACCESS_KEY_ID=$WERCKER_EB_DEPLOY_ACCESS_KEY
export AMAZON_SECRET_ACCESS_KEY=$WERCKER_EB_DEPLOY_SECRET_KEY
export AWS_DEFAULT_REGION=$WERCKER_EB_DEPLOY_REGION
export EB_VERSION_LABEL=$WERCKER_EB_DEPLOY_APP_NAME.$UNIXTIME
export EB_DESCRIPTION=$WERCKER_EB_DEPLOY_ENV_NAME,$WERCKER_GIT_BRANCH
export S3_FILE_KEY=$WERCKER_EB_DEPLOY_APP_NAME/$WERCKER_EB_DEPLOY_APP_NAME.$UNIXTIME.zip
export AWS_CONFIG_FILE=$HOME/.aws/config

info 'create .aws/config ...';
mkdir -p $HOME/.aws
echo '[default]' > $HOME/.aws/config
echo 'output = json' >> $HOME/.aws/config
echo "region = $WERCKER_EB_DEPLOY_REGION" >> $HOME/.aws/config
echo "aws_access_key_id = $WERCKER_EB_DEPLOY_ACCESS_KEY" >> $HOME/.aws/config
echo "aws_secret_access_key = $WERCKER_EB_DEPLOY_SECRET_KEY" >> $HOME/.aws/config

info 'Compress source code ...'
mkdir $WERCKER_EB_DEPLOY_APP_NAME
git archive HEAD --output=$S3_FILE_KEY

info 'copy code to S3 ...'
aws s3 cp --acl private $S3_FILE_KEY "s3://$WERCKER_EB_DEPLOY_S3_BUCKET/$S3_FILE_KEY"

info 'create elasticbeanstalk application-version ...'
aws elasticbeanstalk create-application-version \
    --region $WERCKER_EB_DEPLOY_REGION \
    --application-name $WERCKER_EB_DEPLOY_APP_NAME \
    --version-label $EB_VERSION_LABEL \
    --description $EB_DESCRIPTION \
    --source-bundle "{\"S3Bucket\":\"$WERCKER_EB_DEPLOY_S3_BUCKET\", \"S3Key\":\"$S3_FILE_KEY\"}"

info 'update elasticbeanstalk application ...'
aws elasticbeanstalk update-environment \
    --environment-name $WERCKER_EB_DEPLOY_ENV_NAME \
    --description $EB_DESCRIPTION,$WERCKER_GIT_COMMIT \
    --version-label $EB_VERSION_LABEL
