import json
import random
import shutil
import sys

import boto3
import requests


def perpare_server(version, resource_pack=''):
    build = requests.get(f'https://api.papermc.io/v2/projects/paper/versions/{version}/builds').json()['builds'][-1]

    number = build['build']
    name = build['downloads']['application']['name']

    download_url = f'https://api.papermc.io/v2/projects/paper/versions/{version}/builds/{number}/downloads/{name}'
    print(f'Downloading jar from {download_url}')

    path = f'tmp_{version}_{random.getrandbits(32)}'
    print(f'Server generating in {path}')

    shutil.copytree('templates', path)

    open(f'{path}/server.jar', 'wb').write(requests.get(download_url).content)
    open(f'{path}/eula.txt', 'w').write('eula=true')

    with open(f'{path}/metadata.json', 'w') as metadata:
        json.dump({'version': version}, metadata)

    ssm = boto3.client('ssm')
    password = ssm.get_parameter(Name='mc-rcon-password', WithDecryption=True)['Parameter']['Value']
    open(f'{path}/server.properties', 'a').write(f'rcon.password={password}')

    if resource_pack != '':
        open(f'{path}/server.properties', 'a').write(f'\nresource-pack={resource_pack}')

    return path

if __name__ == "__main__":
    perpare_server("1.20.1" if len(sys.argv) == 1 else sys.argv[1])