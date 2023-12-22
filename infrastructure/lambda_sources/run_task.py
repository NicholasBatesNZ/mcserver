import os
import boto3

TASK_ROLE_ARN = os.environ['TASK_ROLE_ARN']
CLUSTER = "DevCluster"


def lambda_handler(event, context):
    ssm = boto3.client("ssm")
    instance_type = ssm.get_parameter(
        Name="instance-type"
    )["Parameter"]["Value"]

    ec2 = boto3.client("ec2")
    memory = ec2.describe_instance_types(
        InstanceTypes=[instance_type]
    )["InstanceTypes"][0]["MemoryInfo"]["SizeInMiB"]


    ecs = boto3.client("ecs")

    running_tasks = ecs.list_tasks(
        cluster=CLUSTER
    )["taskArns"]
    
    if len(running_tasks) > 0:
        ecs.stop_task(
            cluster=CLUSTER,
            task=running_tasks[0].split("/")[2]
        )

    ecs.run_task(
        cluster=CLUSTER,
        task_definition=event["taskDefinition"],
        overrides={
            "taskRoleArn": TASK_ROLE_ARN,
            "containerOverrides": [{
                "name": "mcserver",
                "memory": memory,
                "environment": [{
                    "name": "MAX_HEAP",
                    "value": f"${memory // 1024}G"
                }]
            }]
        }
    )
