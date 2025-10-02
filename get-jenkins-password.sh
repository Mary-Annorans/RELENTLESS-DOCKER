#!/bin/bash

# Script to get Jenkins admin password
echo "Attempting to get Jenkins admin password..."

# Try to get the password using AWS CLI with SSM
aws ssm send-command \
    --instance-ids "i-04c5eb0276336ec41" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["sudo cat /var/lib/jenkins/secrets/initialAdminPassword"]' \
    --query "Command.CommandId" \
    --output text

echo "Command sent. Waiting for result..."

# Wait a moment for the command to execute
sleep 10

# Get the command result
COMMAND_ID=$(aws ssm list-commands --instance-id "i-04c5eb0276336ec41" --query "Commands[0].CommandId" --output text)

if [ "$COMMAND_ID" != "None" ] && [ "$COMMAND_ID" != "" ]; then
    echo "Getting command output..."
    aws ssm get-command-invocation \
        --command-id "$COMMAND_ID" \
        --instance-id "i-04c5eb0276336ec41" \
        --query "StandardOutputContent" \
        --output text
else
    echo "No command found. Jenkins might still be installing..."
fi

