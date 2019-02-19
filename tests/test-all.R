options(tidyverse.quiet=TRUE)

library(dbplyr, warn.conflicts = FALSE, quietly = TRUE, verbose = FALSE)
library(dplyr, warn.conflicts = FALSE, quietly = TRUE, verbose = FALSE)
library(metis.jars, warn.conflicts = FALSE, quietly = TRUE, verbose = FALSE)
library(metis, warn.conflicts = FALSE, quietly = TRUE, verbose = FALSE)
library(metis.tidy, warn.conflicts = FALSE, quietly = TRUE, verbose = FALSE)

testthat::context("d[b]plyr ops work as expected")

Sys.setenv(
  AWS_S3_STAGING_DIR = "s3://aws-athena-query-results-569593279821-us-east-1"
)

message("Making driver")
drv <- metis::Athena()
testthat::expect_is(drv, "AthenaDriver")

testthat::skip_on_cran()

message("Establishing connection")
if (identical(Sys.getenv("TRAVIS"), "true")) {

  metis::dbConnect(
    drv = drv,
    Schema = "sampledb",
    S3OutputLocation = "s3://aws-athena-query-results-569593279821-us-east-1"
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

testthat::expect_is(con, "AthenaConnection")

message("Sourcing table")
elb_logs <- tbl(con, "elb_logs")

testthat::expect_is(elb_logs, "tbl_AthenaConnection")

message("Filtering and transforming")
filter(elb_logs, grepl("20", elbresponsecode)) %>%
  mutate(
    tsday = as.Date(substring(timestamp, 1L, 10L)),
    host = url_extract_host(url),
    proto_version = regexp_extract(protocol, "([[:digit:]\\.]+)"),
  ) %>%
  select(tsday, host, receivedbytes, requestprocessingtime, proto_version) %>%
  head(1) %>%
  collect() -> out

testthat::expect_is(out$tsday, "Date")
testthat::expect_is(out$host, "character")
testthat::expect_is(out$receivedbytes, "integer64")
testthat::expect_is(out$requestprocessingtime, "numeric")
testthat::expect_is(out$proto_version, "character")
