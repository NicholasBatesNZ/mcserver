import json
import os
import urllib3


def lambda_handler(event, context):
    if event['detail']['name'] != "instance-type":
        return
    
    url = f"https://api.github.com/repos/{os.environ['repo']}/actions/workflows/terraform-apply.yml/dispatches"

    body = {
        "ref": "main"
    }

    headers = {"Authorization": f"Bearer {os.environ['GITHUB_PAT']}"}

    http = urllib3.PoolManager()
    http.request("POST", url, body=json.dumps(body), headers=headers)
