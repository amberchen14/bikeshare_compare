

PROJECT_DIR="$PROCESS"

echo "Project Directory: $PROJECT_DIR"

spark-submit --packages  org.postgresql:postgresql:42.2.13,com.amazonaws:aws-java-sdk:1.7.4,org.apache.hadoop:hadoop-aws:2.7.7 --master "$SPARK_MASTER" $PROJECT_DIR/data_process.py
