#Create Dockerfile for python-app
FROM python:3.8-alpine
LABEL com.blesson.www=V0.1
RUN mkdir -p /app
ADD s3-veri.py /app
ENV BUCKETNAME="qa-private143"
WORKDIR /app
RUN pip install boto3
RUN sed -i s/some-private-bucket/$BUCKETNAME/g s3-veri.py
CMD ["python","s3-veri.py"]
