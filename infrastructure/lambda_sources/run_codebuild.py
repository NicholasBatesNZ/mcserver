import json

import boto3
from botocore.exceptions import ClientError


def lambda_handler(event, context):
    # Log the received S3 event
    print("Received S3 event: " + json.dumps(event))
    
    # Extract the file name from the event
    try:
        s3_bucket_name = event['Records'][0]['s3']['bucket']['name']
        s3_object_key = event['Records'][0]['s3']['object']['key']
        object_name = s3_object_key.split('/')[-1]

        codebuild = boto3.client('codebuild')
        codebuild.start_build(
            projectName="mcserver-build",
            sourceLocationOverride=f"{s3_bucket_name}/{s3_object_key}",
            environmentVariablesOverride=
            [
                {
                    'name': 'IMAGE_TAG',
                    'value': object_name,
                    'type': 'PLAINTEXT'
                }
            ]
        )
        
    except KeyError as e:
        print("Error extracting file name from S3 event: " + str(e))

    except ClientError as e:
        print(e)
