# THIS IS A BIG TODO

aws cloudformation create-stack \
    --stack-name my-iam-policy-stack \
    --template-body file://iam-policy-template.yaml \
    --parameters ParameterKey=PolicyName,ParameterValue=my-iam-policy

# Wait for the IAM policy stack to be created
aws cloudformation wait stack-create-complete \
    --stack-name my-iam-policy-stack

aws cloudformation create-stack \
    --stack-name my-iam-user-stack \
    --template-body file://iam-user-template.yaml \
    --parameters ParameterKey=UserName,ParameterValue=my-iam-user \
                             ParameterKey=PolicyStackName,ParameterValue=my-iam-policy-stack

# Wait for the IAM user stack to be created
aws cloudformation wait stack-create-complete \
    --stack-name my-iam-user-stack

