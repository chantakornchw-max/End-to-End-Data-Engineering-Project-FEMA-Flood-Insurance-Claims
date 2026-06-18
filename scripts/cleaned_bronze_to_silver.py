import os
import logging
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *



def cleaned_bronze_to_silver():

    logging.basicConfig(
        level=logging.INFO, 
        format='%(asctime)s - %(levelname)s - %(message)s'
    )

    spark = (SparkSession.builder
        .appName("cleaned_bronze_to_silver")
        .getOrCreate()
    )


    aws_access_key = os.environ.get("AWS_ACCESS_KEY_ID")
    aws_secret_key = os.environ.get("AWS_SECRET_ACCESS_KEY")
    spark.conf.set("fs.s3a.access.key", aws_access_key)
    spark.conf.set("fs.s3a.secret.key", aws_secret_key)
    spark.conf.set("fs.s3a.endpoint", "s3.ap-southeast-1.amazonaws.com")


    bucket_name = os.environ.get("S3_BUCKET_NAME", "fema-flood-claims-bucket-2026")
    bronze_input_path = f"s3a://{bucket_name}/bronze/raw_data/"
    silver_output_path = f"s3a://{bucket_name}/silver/cleaned_data/fact/"


    try:
        logging.info("Starting clean process...")

        cleaned_df = (
            spark.read.parquet(bronze_input_path)

            # Select columns, Rename, and Change type
            .select(
                col("id").alias("claim_id").cast(StringType()),
                col("floodEvent").alias("flood_event").cast(StringType()),
                
                col("dateOfLoss").alias("date_of_loss").cast(TimestampType()),
                col("yearOfLoss").alias("year_of_loss").cast(IntegerType()),
                col("originalConstructionDate").alias("original_construction_date").cast(TimestampType()),
                
                col("state").alias("state").cast(StringType()),
                col("reportedZipCode").alias("reported_zip_code").cast(StringType()), 
                col("latitude").alias("latitude").cast(DoubleType()),
                col("longitude").alias("longitude").cast(DoubleType()),
                col("ratedFloodZone").alias("rated_flood_zone").cast(StringType()),
                
                col("occupancyType").alias("occupancy_type").cast(IntegerType()),
                col("primaryResidenceIndicator").alias("primary_residence_indicator").cast(IntegerType()),
                col("elevationDifference").alias("elevation_difference").cast(DoubleType()),
                col("waterDepth").alias("water_depth").cast(DoubleType()),
                
                col("buildingPropertyValue").alias("building_property_value").cast(DoubleType()),
                col("totalBuildingInsuranceCoverage").alias("total_building_insurance_coverage").cast(DoubleType()),
                col("buildingDamageAmount").alias("building_damage_amount").cast(DoubleType()),
                col("buildingReplacementCost").alias("building_replacement_cost").cast(DoubleType()),
                col("netBuildingPaymentAmount").alias("net_building_payment_amount").cast(DoubleType()),
                col("totalContentsInsuranceCoverage").alias("total_contents_insurance_coverage").cast(DoubleType()),
                col("contentsDamageAmount").alias("contents_damage_amount").cast(DoubleType()),
                col("netContentsPaymentAmount").alias("net_contents_payment_amount").cast(DoubleType()),
                
                col("buildingDeductibleCode").alias("building_deductible_code").cast(StringType()),
                col("causeOfDamage").alias("cause_of_damage").cast(StringType()),
                col("nonPaymentReasonBuilding").alias("non_payment_reason_building").cast(StringType())
            )

            # Handling NULL values
            .dropna(subset=['claim_id', 'date_of_loss'])
            .withColumn("year_of_loss", year(col("date_of_loss")))
            .fillna("Unknown", subset=[
                "flood_event", 
                "state", 
                "reported_zip_code",
                "rated_flood_zone", 
                "building_deductible_code", 
                "cause_of_damage"
            ])
            .fillna("Not Applicable", subset=["non_payment_reason_building"])
            .fillna(0.0, subset=[
                "building_property_value",
                "total_building_insurance_coverage",
                "building_damage_amount",
                "building_replacement_cost",
                "net_building_payment_amount",
                "total_contents_insurance_coverage",
                "contents_damage_amount",
                "net_contents_payment_amount"
            ])

            # Handling negative values
            .withColumn("building_property_value", abs(col("building_property_value")))
            .withColumn("total_building_insurance_coverage", abs(col("total_building_insurance_coverage")))
            .withColumn("building_damage_amount", abs(col("building_damage_amount")))
            .withColumn("building_replacement_cost", abs(col("building_replacement_cost")))
            .withColumn("net_building_payment_amount", abs(col("net_building_payment_amount")))
            .withColumn("total_contents_insurance_coverage", abs(col("total_contents_insurance_coverage")))
            .withColumn("contents_damage_amount", abs(col("contents_damage_amount")))
            .withColumn("net_contents_payment_amount", abs(col("net_contents_payment_amount")))
            .withColumn("water_depth", abs(col("water_depth")))

            # Handling duplicate and and timestamps
            .dropDuplicates(["claim_id"])
            .withColumn("processed_at", current_timestamp())
        )

        (cleaned_df
            .repartition("year_of_loss")
            .write
            .partitionBy("year_of_loss")
            .mode("overwrite")
            .parquet(silver_output_path)
        )
        logging.info(f"Successfully cleaned and uploaded data to {silver_output_path}")

    except Exception as e:
        logging.error(f"Unexpected error occurred!: {e}")
        raise e

    finally:
        spark.stop()


if __name__ == "__main__":
    cleaned_bronze_to_silver()