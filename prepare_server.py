import os
import random
import sys

import boto3
import requests

def perpare_server(version):
    build = requests.get(f'https://api.papermc.io/v2/projects/paper/versions/{version}/builds').json()['builds'][-1]

    number = build['build']
    name = build['downloads']['application']['name']

    download_url = f'https://api.papermc.io/v2/projects/paper/versions/{version}/builds/{number}/downloads/{name}'
    print(f'Downloading jar from {download_url}')

    path = f'tmp_{random.getrandbits(128)}'
    print(f'Server generating in {path}')

    os.mkdir(path)

    open(f'{path}/server.jar', 'wb').write(requests.get(download_url).content)
    open(f'{path}/eula.txt', 'w').write('eula=true')

    os.system(f'cp Dockerfile {path}/Dockerfile')
    os.system(f'cp ops.json {path}/ops.json')
    os.system(f'cp server.properties {path}/server.properties')

    ssm = boto3.client('ssm')
    password = ssm.get_parameter(Name='mc-rcon-password', WithDecryption=True)['Parameter']['Value']
    open(f'{path}/server.properties', 'a').write(f'rcon.password={password}')

if __name__ == "__main__":
    perpare_server("1.20.1" if len(sys.argv) == 1 else sys.argv[1])