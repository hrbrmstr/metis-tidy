context("d[b]plyr ops work as expected")

Sys.setenv(
  AWS_S3_STAGING_DIR = "s3://aws-athena-query-results-569593279821-us-east-1"
)

library(metis)
library(dbplyr)
library(dplyr)

drv <- metis::Athena()

skip_on_cran()

if (identical(Sys.getenv("TRAVIS"), "true")) {

  metis::dbConnect(
    drv = drv,
    Schema = "sampledb",
    S3OutputLocation = "s3://aws-athena-query-results-569593279821-us-east-1",
  ) -> con

} else {

  metis::dbConnect(
    drv = drv,
    Schema = "sampledb",
    AwsCredentialsProviderClass = "com.simba.athena.amazonaws.auth.PropertiesFileCredentialsProvider",
    AwsCredentialsProviderArguments = path.expand("~/.aws/athenaCredentials.props"),
    S3OutputLocation = "s3://aws-athena-query-results-569593279821-us-east-1",
  ) -> con

}

metis::dbConnect(
  drv,
  Schema = "sampledb",
  AwsCredentialsProviderClass = "com.simba.athena.amazonaws.auth.PropertiesFileCredentialsProvider",
  AwsCredentialsProviderArguments = path.expand("~/.aws/athenaCredentials.props")
) -> con

expect_is(con, "AthenaConnection")

elb_logs <- tbl(con, "elb_logs")

expect_is(elb_logs, "tbl_AthenaConnection")

filter(elb_logs, grepl("20", elbresponsecode)) %>%
  mutate(
    tsday = as.Date(substring(timestamp, 1L, 10L)),
    host = url_extract_host(url),
    proto_version = regexp_extract(protocol, "([[:digit:]\\.]+)"),
  ) %>%
  select(tsday, host, receivedbytes, requestprocessingtime, proto_version) %>%
  head(1) %>%
  collect() -> out

expect_is(out$tsday, "Date")
expect_is(out$host, "character")
expect_is(out$receivedbytes, "integer64")
expect_is(out$requestprocessingtime, "numeric")
expect_is(out$proto_version, "character")
