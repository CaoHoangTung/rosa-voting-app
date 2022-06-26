IMAGE_TAG=latest

echo "Trigerring openshift webhook"
oclogin=`aws secretsmanager get-secret-value --secret-id ROSA/login-cmd --output=text | head -1 | cut -f4 -d'"'`
$oclogin
oc config set-context --current --namespace=rosa-voting-app
buildConfig="vote"
secret_name=`oc get bc $buildConfig -o jsonpath='{.spec.triggers[?(@.generic)].generic.secretReference.name}'`
webhookSecretKey=`oc get secret $secret_name -o jsonpath='{.data.WebHookSecretKey}' | base64 -d`
oc describe bc $buildConfig |grep webhooks | awk '{print $2}' | sed -e s/\<secret\>/$webhookSecretKey/
webhookURL=`oc describe bc $buildConfig |grep webhooks | awk '{print $2}' | sed -e s/\<secret\>/$webhookSecretKey/`
curl -kX POST $webhookURL
