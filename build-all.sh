IMAGE_TAG=latest


# docker build -t $IMAGE_REPO_NAME_VOTE ./voting-app/vote
# docker build -t $IMAGE_REPO_NAME_RESULT ./voting-app/result
# docker build -t $IMAGE_REPO_NAME_WORKER ./voting-app/worker

# echo "Build done"

# docker tag $IMAGE_REPO_NAME_VOTE:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME_VOTE:$IMAGE_TAG
# docker tag $IMAGE_REPO_NAME_RESULT:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME_RESULT:$IMAGE_TAG
# docker tag $IMAGE_REPO_NAME_WORKER:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME_WORKER:$IMAGE_TAG

# echo "Tag done"

# docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME_VOTE:$IMAGE_TAG
# docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME_RESULT:$IMAGE_TAG
# docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME_WORKER:$IMAGE_TAG

# echo "Pushed to ECR"

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