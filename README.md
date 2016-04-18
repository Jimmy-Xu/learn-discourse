run discourse(standalone) with discourse_docker
=================================================

**REF**
```
http://learndiscourse.org/
https://github.com/discourse/discourse/blob/master/docs/INSTALL-cloud.md/
```

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 -->

- [quickstart](#quickstart)
- [step by step](#step-by-step)
	- [download discourse_docker](#download-discoursedocker)
	- [config](#config)
	- [check config finally](#check-config-finally)
	- [bootstrap](#bootstrap)
	- [start](#start)
	- [enter container](#enter-container)
- [integrate slack](#integrate-slack)
	- [config slack](#config-slack)
		- [create new channel](#create-new-channel)
		- [create new Incoming WebHooks](#create-new-incoming-webhooks)
	- [config discourse](#config-discourse)
		- [modify app.yml](#modify-appyml)
		- [rebuild app](#rebuild-app)
		- [set slack in discourse](#set-slack-in-discourse)
			- [check slack plugins is installed](#check-slack-plugins-is-installed)
			- [modify settings for slack](#modify-settings-for-slack)

<!-- /TOC -->

# quickstart
```
//just run the following script
./util.sh
```

# step by step

## download discourse_docker
```
cd ~
git clone https://github.com/discourse/discourse_docker.git
cd ~/discourse_docker
```

## config
```
cp samples/standalone.yml containers/app.yml

//basic config
PORT='8080'
EMAIL='support@xxxxx.sh'
URL='forum.xxxxx.sh'

//config smtp
SMTP_SERVER='email-smtp.us-west-2.amazonaws.com'
SMTP_PORT='587'
SMTP_SSL_TYPE='true'
SMTP_USERNAME='<username>'
SMTP_PASSWORD='<password>'

sed -i "s%\- \".*:80\"%\- \"${PORT}:80\"%g" containers/app.yml
sed -i "s%DISCOURSE_DEVELOPER_EMAILS: '.*'*%DISCOURSE_DEVELOPER_EMAILS: '${EMAIL}'%g" containers/app.yml
sed -i "s%DISCOURSE_HOSTNAME: '.*'*%DISCOURSE_HOSTNAME: '${URL}'%g" containers/app.yml

sed -i "s%.*DISCOURSE_SMTP_ADDRESS: .*%  DISCOURSE_SMTP_ADDRESS: ${SMTP_SERVER}%g" containers/app.yml
sed -i "s%.*DISCOURSE_SMTP_PORT: .*%  DISCOURSE_SMTP_PORT: ${SMTP_PORT}%g" containers/app.yml
sed -i "s%.*DISCOURSE_SMTP_USER_NAME: .*%  DISCOURSE_SMTP_USER_NAME: ${SMTP_USERNAME}%g" containers/app.yml
sed -i "s%.*DISCOURSE_SMTP_PASSWORD: .*%  DISCOURSE_SMTP_PASSWORD: ${SMTP_PASSWORD}%g" containers/app.yml
sed -i "s%.*DISCOURSE_SMTP_ENABLE_START_TLS: .*%  DISCOURSE_SMTP_ENABLE_START_TLS: ${SMTP_SSL_TYPE}%g" containers/app.yml
```

## check config finally
```
cat containers/app.yml | grep -E '(^  DISCOURSE_SMTP|EMAILS:|HOSTNAME:|:80")'
```

## bootstrap
```
sudo ln -s $(which docker) /usr/bin/docker.io
./launcher bootstrap app
```

## start
```
./launcher start app
```

## enter container
```
./launcher enter app
```

# integrate slack

- Post all new posts(topic, reply) to Slack

## config slack

### create new channel
```
create a new public channel, name is 'forum'
```

### create new Incoming WebHooks
```
go to https://<team-name>.slack.com/apps/manage/custom-integrations
 -> Add Configuration
   -> Integration Settings
	    - Post to Channel: #forum
	    - Webhook URL    : https://hooks.slack.com/services/T05xxxxxx/B1xxxxxxx/ILVxxxxxxxxxxxxxxxxxxxxE
	    - Customize Name : ForumBot
	    - Customize Icon : <Upload an image> as forum icon
```

## config discourse

### modify app.yml
```
//modify containers/app.yml, append '- git clone https://github.com/bernd/discourse-slack-plugin.git'
	...
	hooks:
	  after_code:
	    - exec:
	        cd: $home/plugins
	        cmd:
	          - git clone https://github.com/discourse/docker_manager.git
	          - git clone https://github.com/bernd/discourse-slack-plugin.git
	...
```
### rebuild app
```
$ ./launcher rebuild
```

### set slack in discourse

#### check slack plugins is installed
```
Admin -> Plugins -> slack Enabled is 'Y'
```

#### modify settings for slack
```
Admin -> Settings -> Slack
	- slack enabled: <checked>
	- slack url       : https://hooks.slack.com/services/T05xxxxxx/B1xxxxxxx/ILVxxxxxxxxxxxxxxxxxxxxE
	- slack channel   : forum
	- slack emoji     : :discourse:
	- slack posts     : <checked>
	- slack full names: <checked>

//create customized emoji ":discourse:"
REF: https://get.slack.help/hc/en-us/articles/206870177-Creating-custom-emoji
go to https://<team-name>.slack.com/customize/emoji
1) Choose a name: "discourse"
2) Upload your emoji image
```
