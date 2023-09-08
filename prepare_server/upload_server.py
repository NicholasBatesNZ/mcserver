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