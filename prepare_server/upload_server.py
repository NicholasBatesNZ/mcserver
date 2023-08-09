import shutil

import boto3
from botocore.exceptions import ClientError


def upload_server(tag, folder):
    shutil.make_archive(folder, 'zip', folder)

    s3 = boto3.client('s3')
    s3.upload_file(f'{folder}.zip', 'mcserver-rawfiles', f'zips/{tag}.zip')

    codebuild = boto3.client('codebuild')
    try:
        codebuild.start_build(
            projectName="mcserver-build",
            sourceLocationOverride=f"mcserver-rawfiles/zips/{tag}.zip",
            environmentVariablesOverride=
            [
                {
                    'name': 'IMAGE_TAG',
                    'value': tag,
                    'type': 'PLAINTEXT'
                }
            ]
        )
    except ClientError as e:
        print(e)

    ecs = boto3.client('ecs')
    ecs.register_task_definition(
        family=tag,
        tags=[
            {
                'key': 'ryanFriendly',
                'value': 'yes'
            }
        ],
        executionRoleArn="arn:aws:iam::251780365797:role/ecsTaskExecutionRole",
        networkMode="host",
        containerDefinitions=[
            {
                "name": "mcserver",
                "image": f"public.ecr.aws/l3c0s8n4/mcserver:{tag}",
                "portMappings": [
                    {
                        "containerPort": 25565,
                        "hostPort": 25565,
                        "protocol": "tcp"
                    },
                    {
                        "containerPort": 25565,
                        "hostPort": 25565,
                        "protocol": "udp"
                    },
                    {
                        "containerPort": 25575,
                        "hostPort": 25575,
                        "protocol": "tcp"
                    }
                ],
                "essential": True
            }
        ],
        memory="3072"
    )