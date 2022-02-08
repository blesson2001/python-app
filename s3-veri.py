import boto3, botocore
s3 = boto3.resource('s3')
bucket_name = 'some-private-bucket'
#bucket_name = 'bucket-to-check'

from datetime import datetime
bucket = s3.Bucket(bucket_name)
def check_bucket(bucket):
    try:
        s3.meta.client.head_bucket(Bucket=bucket_name)
        print("Bucket Exists!")
        return True
    except botocore.exceptions.ClientError as e:
        # If a client error is thrown, then check that it was a 404 error.
        # If it was a 404 error, then the bucket does not exist.
        error_code = int(e.response['Error']['Code'])
        if error_code == 403:
            print("Private Bucket. Forbidden Access!")
            return True
        elif error_code == 404:
            print("Bucket Does Not Exist!")
            #return False
            s3_client = boto3.client('s3')
            s3_client.create_bucket(Bucket=bucket_name)
            print("Bucket created")

check_bucket(bucket)

txt_data = b'This is the content of the file uploaded from python boto3 asdfasdf'
date = datetime.now().strftime("%Y_%m_%d-%I:%M:%S_%p")
object = s3.Object(bucket_name, f'file_uploaded_by_boto3.txt_{date}')


result = object.put(Body=txt_data)

print(f"file uploaded with date {date}")

