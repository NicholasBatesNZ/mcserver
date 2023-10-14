import json
import os
import shutil

import boto3


def upload_server(tag, folder):
    definition = {}
    with open(f'{folder}/definition.json', 'r') as file:
        definition = json.load(file)

    definition['family'] = tag
    definition['containerDefinitions'][0]['image'] = f'public.ecr.aws/l3c0s8n4/mcserver:{tag}'

    with open(f'{folder}/definition.json', 'w') as file:
        json.dump(definition, file, indent=2)

    shutil.make_archive(folder, 'zip', folder)

    s3 = boto3.client('s3')
    s3.upload_file(f'{folder}.zip', 'mcserver-rawfiles', f'zips/{tag}.zip')

    os.unlink(f'{folder}.zip')