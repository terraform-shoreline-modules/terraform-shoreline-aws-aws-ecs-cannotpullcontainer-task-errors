resource "shoreline_notebook" "cannotpullcontainer_task_errors_in_amazon_elastic_container_service" {
  name       = "cannotpullcontainer_task_errors_in_amazon_elastic_container_service"
  data       = file("${path.module}/data/cannotpullcontainer_task_errors_in_amazon_elastic_container_service.json")
  depends_on = [shoreline_action.invoke_subnet_internet_access,shoreline_action.invoke_ecs_run_task_script,shoreline_action.invoke_ecs_update_task_definition]
}

resource "shoreline_file" "subnet_internet_access" {
  name             = "subnet_internet_access"
  input_file       = "${path.module}/data/subnet_internet_access.sh"
  md5              = filemd5("${path.module}/data/subnet_internet_access.sh")
  description      = "The task is launched in a private subnet without a NAT gateway configured to route requests to the internet."
  destination_path = "/tmp/subnet_internet_access.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "ecs_run_task_script" {
  name             = "ecs_run_task_script"
  input_file       = "${path.module}/data/ecs_run_task_script.sh"
  md5              = filemd5("${path.module}/data/ecs_run_task_script.sh")
  description      = "Specify ENABLED for Auto-assign public IP when launching the task for tasks in public subnets, and specify DISABLED for Auto-assign public IP when launching the task for tasks in private subnets, and configure a NAT gateway in your VPC to route requests to the internet."
  destination_path = "/tmp/ecs_run_task_script.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "ecs_update_task_definition" {
  name             = "ecs_update_task_definition"
  input_file       = "${path.module}/data/ecs_update_task_definition.sh"
  md5              = filemd5("${path.module}/data/ecs_update_task_definition.sh")
  description      = "change the latest image for task definition"
  destination_path = "/tmp/ecs_update_task_definition.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_action" "invoke_subnet_internet_access" {
  name        = "invoke_subnet_internet_access"
  description = "The task is launched in a private subnet without a NAT gateway configured to route requests to the internet."
  command     = "`chmod +x /tmp/subnet_internet_access.sh && /tmp/subnet_internet_access.sh`"
  params      = ["TASK_ID","SUBNET_ID","VPC_ID","CLUSTER"]
  file_deps   = ["subnet_internet_access"]
  enabled     = true
  depends_on  = [shoreline_file.subnet_internet_access]
}

resource "shoreline_action" "invoke_ecs_run_task_script" {
  name        = "invoke_ecs_run_task_script"
  description = "Specify ENABLED for Auto-assign public IP when launching the task for tasks in public subnets, and specify DISABLED for Auto-assign public IP when launching the task for tasks in private subnets, and configure a NAT gateway in your VPC to route requests to the internet."
  command     = "`chmod +x /tmp/ecs_run_task_script.sh && /tmp/ecs_run_task_script.sh`"
  params      = ["TASK_ID","SUBNET_ID","VPC_ID"]
  file_deps   = ["ecs_run_task_script"]
  enabled     = true
  depends_on  = [shoreline_file.ecs_run_task_script]
}

resource "shoreline_action" "invoke_ecs_update_task_definition" {
  name        = "invoke_ecs_update_task_definition"
  description = "change the latest image for task definition"
  command     = "`chmod +x /tmp/ecs_update_task_definition.sh && /tmp/ecs_update_task_definition.sh`"
  params      = ["ECR_REPOSITORY_URI","REPOSITORY_NAME","TASK_DEFINITION_ARN"]
  file_deps   = ["ecs_update_task_definition"]
  enabled     = true
  depends_on  = [shoreline_file.ecs_update_task_definition]
}

