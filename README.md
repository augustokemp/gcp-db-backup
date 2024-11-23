### Google Cloud SQL DB Exporter

This is an automated shell script that gets you an *GCloud SQL database dump* to update your development database container.
It's a handful tool for working with a *PostgreSQL database* using *Docker Compose*.
Besides, all your private configuration data is kept by yourself on an `.env` local file.


#### Requirements
- GCP SQL with a PostgreSQL database & a Google Bucket to store the database dump;
- Install GCloud CLI from https://cloud.google.com/sdk/docs/install#linux;

#### Before we begin
- Start `gcloud init` and log in;
- Select the gcp project where the SQL instance and the bucket are located;
- Clone this repository;
- Create an .env file with the following content:
```
# Docker settings
STACK_NAME=your-docker-stack-name
DB_VOLUME_NAME=your-docker-db-volume-name

# User settings
LOCAL_PATH="/path/to/your/local/dump" # Local path to db dump
REPOSITORY_PATH="/path/to/your/repository" # Local path to yout repository

# Google GCP settings
PROJECT_ID=your-google-project-id # Project ID
INSTANCE_ID=you-gcp-sql-instance-id # DB GCP instance ID
DB_NAME=your-database-name # Database name under GCP instance
BUCKET_NAME=you-google-bucket-name # Bucket to export dump
REMOTE_PATH="gs://${BUCKET_NAME}"  # Remote path to dump


# Script config - Do not change this
TODAY=$(date +"%Y-%m-%d")
FILE_NAME="${TODAY}.sql"
```

#### Commands
- `bash docker-restore.sh`: Performs all actions, getting your stack up with the latest db dump;
- `export`: Exports a database dump from GSQL to GBucket
- `download`: Downloads the database dump from GBucket to the `$LOCAL_PATH`;
- `prune --local`: Removes old database dumps from your PC;
- `prune --remote`: Removes old database dumps from GBucket;

#### Considerations
- If you don't work with Docker, or just want the dump on your PC, it's perfectly fine to just run `bash export.sh && bash download.sh`