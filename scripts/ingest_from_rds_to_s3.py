import sys  
import boto3
import json
import logging
from pyspark.sql import SparkSession


def get_db_credentials(secret_name, aws_access_key, aws_secret_key, region_name="ap-southeast-1"):

    client = boto3.client(
        service_name='secretsmanager',
        region_name=region_name,
        aws_access_key_id=aws_access_key,
        aws_secret_access_key=aws_secret_key
    )
    
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        secret = json.loads(get_secret_value_response['SecretString'])
        return secret
    
    except Exception as e:
        logging.error(f"Failed to retrieve password from Secrets Manager!: {e}")
        raise e


def ingest_from_rds_to_s3():

    logging.basicConfig(
        level=logging.INFO, 
        format='%(asctime)s - %(levelname)s - %(message)s'
    )

    spark = (SparkSession.builder
        .appName("ingest_from_rds_to_s3")
        .getOrCreate()
    )

    aws_access_key = sys.argv[1]
    aws_secret_key = sys.argv[2]
    # spark.sparkContext._jsc.hadoopConfiguration().set("fs.s3a.access.key", aws_access_key)
    # spark.sparkContext._jsc.hadoopConfiguration().set("fs.s3a.secret.key", aws_secret_key)
    # spark.sparkContext._jsc.hadoopConfiguration().set("fs.s3a.endpoint", "s3.ap-southeast-1.amazonaws.com")

    # spark.conf.set("spark.hadoop.fs.s3a.access.key", aws_access_key)
    # spark.conf.set("spark.hadoop.fs.s3a.secret.key", aws_secret_key)
    # spark.conf.set("spark.hadoop.fs.s3a.endpoint", "s3.ap-southeast-1.amazonaws.com")

    # spark.conf.set("fs.s3a.access.key", aws_access_key)
    # spark.conf.set("fs.s3a.secret.key", aws_secret_key)
    # spark.conf.set("fs.s3a.endpoint", "s3.ap-southeast-1.amazonaws.com") 

    table_name = "public.raw_fema_claims"
    bucket_name = sys.argv[3]
    bronze_output_path = f"s3://{bucket_name}/bronze/raw_data/"

    try:

        db_creds = get_db_credentials('fema/rds_credentials', aws_access_key, aws_secret_key)
    
        rds_endpoint = db_creds['host']
        db_user = db_creds['username']
        db_password = db_creds['password']
        
        jdbc_url = f"jdbc:postgresql://{rds_endpoint}:5432/fema_flood_db"
        connection_properties = {
            "user": db_user, 
            "password": db_password,
            "driver": "org.postgresql.Driver" 
        }

        logging.info("Starting ingest raw data from RDS...")

        df = (spark.read.format("jdbc")
            .option("url", jdbc_url)
            .option("dbtable", table_name)
            .option("user", connection_properties["user"])
            .option("password", connection_properties["password"])
            .option("driver", connection_properties["driver"])
            .option("partitionColumn", "row_num")
            .option("lowerBound", "1")
            .option("upperBound", "3000000")
            .option("numPartitions", "10")
            .load()
        )

        (df.write
            .mode("overwrite")
            .parquet(bronze_output_path)
        )

        logging.info(f"Successfully uploaded data to {bronze_output_path}")

    except Exception as e:
        logging.error(f"Unexpected error occurred!: {e}")
        raise e 

    finally:
        spark.stop()

if __name__ == "__main__":
    ingest_from_rds_to_s3()