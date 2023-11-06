import json
import boto3
import os

# Retrieve environment variables
HOSTED_ZONE_ID = os.environ['HOSTED_ZONE_ID']
RECORD_NAME = os.environ['RECORD_NAME']

def get_instance_public_ip(instance_id):
    ec2_client = boto3.client('ec2')
    
    try:
        response = ec2_client.describe_instances(InstanceIds=[instance_id])
        reservations = response['Reservations']
        
        if reservations:
            instances = reservations[0]['Instances']
            
            if instances:
                return instances[0].get('PublicIpAddress')
    except Exception as e:
        print(f"Error getting public IP for instance {instance_id}: {str(e)}")
    
    return None

def lambda_handler(event, context):
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])
    
    # Check if the SNS message corresponds to an EC2 instance launch or termination
    event_type = sns_message.get('Event')
    instance_id = sns_message.get('EC2InstanceId')
    
    route53_client = boto3.client('route53')
    
    try:
        if event_type == 'autoscaling:EC2_INSTANCE_LAUNCH':
            # Get the public IP of the instance
            public_ip = get_instance_public_ip(instance_id)
            
            if public_ip:
                # Update Route 53 A record
                route53_client.change_resource_record_sets(
                    HostedZoneId=HOSTED_ZONE_ID,
                    ChangeBatch={
                        'Changes': [
                            {
                                'Action': 'UPSERT',
                                'ResourceRecordSet': {
                                    'Name': RECORD_NAME,
                                    'Type': 'A',
                                    'TTL': 300,  # TTL in seconds
                                    'ResourceRecords': [{'Value': public_ip}],
                                }
                            }
                        ]
                    }
                )
                print(f"Updated A record for {RECORD_NAME} with IP {public_ip}")
            else:
                print(f"Public IP not found for instance {instance_id}. Skipping record update.")
        
        
        # elif event_type == 'autoscaling:EC2_INSTANCE_TERMINATE':
        #     route53_client.change_resource_record_sets(
        #         HostedZoneId=HOSTED_ZONE_ID,
        #         ChangeBatch={
        #             'Changes': [
        #                 {
        #                     'Action': 'DELETE',
        #                     'ResourceRecordSet': {
        #                         'Name': RECORD_NAME,
        #                         'Type': 'A',
        #                         'TTL': 300,  # TTL in seconds
        #                         'ResourceRecords': [{'Value': public_ip}]
        #                     }
        #                 }
        #             ]
        #         }
        #     )
        #     print(f"Deleted A record for {RECORD_NAME}")
            
        else:
            print(f"Ignoring event of type: {event_type}")
            
    except Exception as e:
        print(f"Error updating/deleting A record: {str(e)}")
