import shutil

import boto3


def upload_server(tag, folder):
    shutil.make_archive(folder, 'zip', folder)

    s3 = boto3.client('s3')
    s3.upload_file(f'{folder}.zip', 'mcserver-rawfiles', f'zips/{tag}.zip')
