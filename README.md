[![Travis-CI Build Status](https://travis-ci.org/hrbrmstr/metis-tidy.svg?branch=master)](https://travis-ci.org/hrbrmstr/metis-tidy) 
[![Coverage Status](https://codecov.io/gh/hrbrmstr/metis-tidy/branch/master/graph/badge.svg)](https://codecov.io/gh/hrbrmstr/metis-tidy
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/metis.tidy)](https://cran.r-project.org/package=metis.tidy)

# metis.tidy

Access and Query Amazon Athena via the Tidyverse

## Description

Methods are provided to use the ‘metis’ JDBC/DBI interface via the
Tidyverse (e.g. ‘dbplyr’/‘dplyr’ idioms).

## What’s Inside The Tin?

Lightweight helpers to make it easier to `filter` and `mutate` plus type
support for Athena `BIGINT` (64-bit integers).

## Installation

``` r
devtools::install_git("https://git.sr.ht/~hrbrmstr/metis-tidy")
# OR
devtools::install_gitlab("hrbrmstr/metis-tidy")
# OR
devtools::install_github("hrbrmstr/metis-tidy")
```

## Usage

``` r
library(metis.tidy)

# current verison
packageVersion("metis.tidy")
```

    ## [1] '0.3.0'

### Basic Setup (using an alternate provider)

``` r
library(metis.tidy)
library(tidyverse)

metis::dbConnect(
  metis::Athena(),
  Schema = "sampledb",
  AwsCredentialsProviderClass = "com.simba.athena.amazonaws.auth.PropertiesFileCredentialsProvider",
  AwsCredentialsProviderArguments = path.expand("~/.aws/athenaCredentials.props")
) -> con

elb_logs <- tbl(con, "elb_logs")

glimpse(elb_logs)
```

    ## Observations: ??
    ## Variables: 16
    ## Database: AthenaConnection
    ## $ timestamp             <chr> "2014-09-29T03:00:52.641389Z", "2014-09-29T03:01:23.603288Z", "2014-09-29T03:01:54.6438…
    ## $ elbname               <chr> "lb-demo", "lb-demo", "lb-demo", "lb-demo", "lb-demo", "lb-demo", "lb-demo", "lb-demo",…
    ## $ requestip             <chr> "252.225.51.44", "252.43.130.244", "248.52.123.119", "246.118.11.120", "240.201.80.176"…
    ## $ requestport           <int> 41423, 41423, 41423, 41423, 41423, 41423, 41423, 41423, 41423, 41423, 41423, 41423, 414…
    ## $ backendip             <chr> "246.185.32.192", "246.5.160.209", "252.12.154.122", "246.191.203.13", "247.27.176.211"…
    ## $ backendport           <int> 8888, 8899, 8000, 8888, 8888, 8888, 8888, 8888, 8000, 8000, 8888, 8888, 8888, 8899, 888…
    ## $ requestprocessingtime <dbl> 0.000095, 0.000090, 0.000087, 0.000089, 0.000090, 0.000093, 0.000092, 0.000094, 0.00010…
    ## $ backendprocessingtime <dbl> 0.035755, 0.048942, 0.050951, 0.046141, 0.039483, 0.052850, 0.032934, 0.046127, 0.04017…
    ## $ clientresponsetime    <dbl> 5.8e-05, 5.5e-05, 5.0e-05, 4.9e-05, 4.8e-05, 5.4e-05, 5.1e-05, 4.8e-05, 4.8e-05, 4.9e-0…
    ## $ elbresponsecode       <chr> "200", "200", "200", "200", "200", "200", "200", "200", "200", "200", "200", "200", "20…
    ## $ backendresponsecode   <chr> "200", "400", "200", "200", "200", "200", "404", "200", "200", "403", "404", "200", "20…
    ## $ receivedbytes         <S3: integer64> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
    ## $ sentbytes             <S3: integer64> 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,…
    ## $ requestverb           <chr> "GET", "GET", "GET", "GET", "GET", "GET", "GET", "GET", "GET", "GET", "GET", "GET", "GE…
    ## $ url                   <chr> "http://www.abcxyz.com:80/jobbrowser/?format=json&state=running&user=248nnm5", "http://…
    ## $ protocol              <chr> "HTTP/1.1", "HTTP/1.1", "HTTP/1.1", "HTTP/1.1", "HTTP/1.1", "HTTP/1.1", "HTTP/1.1", "HT…

#### Using custom Athena functions

``` r
filter(elb_logs, elbresponsecode == "200") %>% 
  mutate(
    tsday = as.Date(substring(timestamp, 1L, 10L)),
    host = url_extract_host(url),
    proto_version = regexp_extract(protocol, "([[:digit:]\\.]+)"),
  ) %>% 
  select(tsday, host, receivedbytes, requestprocessingtime, proto_version) %>% 
  glimpse()
```

    ## Observations: ??
    ## Variables: 5
    ## Database: AthenaConnection
    ## $ tsday                 <date> 2014-09-26, 2014-09-26, 2014-09-26, 2014-09-26, 2014-09-26, 2014-09-26, 2014-09-26, 20…
    ## $ host                  <chr> "www.abcxyz.com", "www.abcxyz.com", "www.abcxyz.com", "www.abcxyz.com", "www.abcxyz.com…
    ## $ receivedbytes         <S3: integer64> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
    ## $ requestprocessingtime <dbl> 0.000074, 0.000102, 0.000056, 0.000048, 0.000047, 0.000087, 0.000095, 0.000049, 0.00005…
    ## $ proto_version         <chr> "1.1", "1.1", "1.1", "1.1", "1.1", "1.1", "1.1", "1.1", "1.1", "1.1", "1.1", "1.1", "1.…

#### All the types work. Some are useful.

``` r
tbl(con, sql("
SELECT
  CAST('chr' AS CHAR(4)) achar,
  CAST('varchr' AS VARCHAR) avarchr,
  CAST(SUBSTR(timestamp, 1, 10) AS DATE) AS tsday,
  CAST(100.1 AS DOUBLE) AS justadbl,
  CAST(127 AS TINYINT) AS asmallint,
  CAST(100 AS INTEGER) AS justanint,
  CAST(100000000000000000 AS BIGINT) AS abigint,
  CAST(('GET' = 'GET') AS BOOLEAN) AS is_get,
  ARRAY[1, 2, 3] AS arr,
  ARRAY['1', '2, 3', '4'] AS arr,
  MAP(ARRAY['foo', 'bar'], ARRAY[1, 2]) AS mp,
  CAST(ROW(1, 2.0) AS ROW(x BIGINT, y DOUBLE)) AS rw,
  CAST('{\"a\":1}' AS JSON) js
FROM elb_logs
LIMIT 1
")) %>% 
  glimpse()
```

    ## Observations: ??
    ## Variables: 13
    ## Database: AthenaConnection
    ## $ achar     <chr> "chr "
    ## $ avarchr   <chr> "varchr"
    ## $ tsday     <date> 2014-09-26
    ## $ justadbl  <dbl> 100.1
    ## $ asmallint <int> 127
    ## $ justanint <int> 100
    ## $ abigint   <S3: integer64> 100000000000000000
    ## $ is_get    <lgl> TRUE
    ## $ arr       <chr> "1, 2, 3"
    ## $ arr       <chr> "1, 2, 3, 4"
    ## $ mp        <chr> "{bar=2, foo=1}"
    ## $ rw        <chr> "{x=1, y=2.0}"
    ## $ js        <chr> "\"{\\\"a\\\":1}\""

``` r
cloc::cloc_pkg_md()
```

| Lang | \# Files |  (%) | LoC |  (%) | Blank lines |  (%) | \# Lines |  (%) |
| :--- | -------: | ---: | --: | ---: | ----------: | ---: | -------: | ---: |
| R    |        6 | 0.86 | 156 | 0.75 |          18 | 0.42 |       26 | 0.41 |
| Rmd  |        1 | 0.14 |  53 | 0.25 |          25 | 0.58 |       38 | 0.59 |

## Code of Conduct

Please note that this project is released with a [Contributor Code of
Conduct](CONDUCT.md). By participating in this project you agree to
abide by its terms.
