1. Download jar and setup initial properties

`py prepare_server.py {VERSION}`

2. Make sure everything is kosher and optionally drop in world file and/or run server once for paper to generate the things (if you don't now it will slow down every subsequent run)

3. Build Docker image

`sudo docker build -t mcserver:{TAG} .`

4. Optionally test locally

`sudo docker run -p 25565:25565 -e MAX_HEAP={MEMORY} mcserver`

5. Tag image again (idk man I'm just following aws docs)

`sudo docker tag mcserver:{TAG} public.ecr.aws/l3c0s8n4/mcserver:{TAG}`

6. Auth to ECR

`aws ecr-public get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin public.ecr.aws/l3c0s8n4`

7. Push to ECR

`sudo docker push public.ecr.aws/l3c0s8n4/mcserver:{TAG}`
