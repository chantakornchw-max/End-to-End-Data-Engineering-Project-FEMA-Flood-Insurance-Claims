import sys
import logging
from pyspark.sql import SparkSession


def fact_silver_to_gold():

    logging.basicConfig(
        level=logging.INFO, 
        format='%(asctime)s - %(levelname)s - %(message)s'
    )

    spark = (SparkSession.builder
        .appName("silver_to_gold_fact")
        .getOrCreate()
    )

    bucket_name = sys.argv[3]
    silver_input_path = f"s3://{bucket_name}/silver/cleaned_data/fact/"
    gold_output_path = f"s3://{bucket_name}/gold/fact/"

    try:
        logging.info("Starting load Fact Table from Silver to Gold...")

        df_fact = spark.read.parquet(silver_input_path)

        (df_fact
            .write
            .format("delta") 
            .partitionBy("year_of_loss")
            .mode("overwrite")
            .option("path", gold_output_path) 
            .saveAsTable("default.gold_fact_fema_claims") 
        )

        logging.info(f"Successfully loaded Fact table to {gold_output_path}")

    except Exception as e:
        logging.error(f"Unexpected error occurred!: {e}")
        raise e

    finally:
        spark.stop()

if __name__ == "__main__":
    fact_silver_to_gold()