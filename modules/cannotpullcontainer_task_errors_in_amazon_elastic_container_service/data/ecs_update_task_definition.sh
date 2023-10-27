

#!/bin/bash

# Set variables

TASK_DEFINITION_ARN=${TASK_DEFINITION_ARN}

REPOSITORY_URI=${ECR_REPOSITORY_URI}





TASK_DEFINITION_NAME=$(echo $TASK_DEFINITION_ARN | awk -F'/' '{print $2}' | awk -F':' '{print $1}')

CONTAINER_NAME=$(aws ecs describe-task-definition --task-definition $TASK_DEFINITION_ARN --query "taskDefinition.containerDefinitions[].name" --output text)

REPOSITORY_NAME=$(echo $REPOSITORY_URI | awk -F '/' '{print $NF}')

IMAGE_NAME=$(aws ecr describe-images --repository-name $REPOSITORY_NAME | jq '.imageDetails | max_by(.imagePushedAt) | .imageTags[0]')



# Update task definition with new image

echo "Updating task definition $TASK_DEFINITION with new image $REPOSITORY_URI:$IMAGE_NAME"

aws ecs register-task-definition --family $TASK_DEFINITION \

  --container-definitions "$(aws ecs describe-task-definition --task-definition $TASK_DEFINITION_ARN \

  | jq --arg containerName $CONTAINER_NAME --arg newImage $REPOSITORY_URI:$IMAGE_NAME \

  '.taskDefinition.containerDefinitions |= map(if .name == $containerName then .image = $newImage else . end)')"



# Check for errors

if [ $? -eq 0 ]; then

  echo "Task definition $TASK_DEFINITION updated successfully with new image $REPOSITORY_URI:$IMAGE_NAME"

else

  echo "Error updating task definition $TASK_DEFINITION with new image $REPOSITORY_URI:$IMAGE_NAME"

fi