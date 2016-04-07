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
