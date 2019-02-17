
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
    ## $ timestamp             <chr> "2014-09-26T22:00:22.979295Z", "2014-09-26T22:29:23.126181Z", "2014-09-26T22:29:28.5918…
    ## $ elbname               <chr> "lb-demo", "lb-demo", "lb-demo", "lb-demo", "lb-demo", "lb-demo", "lb-demo", "lb-demo",…
    ## $ requestip             <chr> "247.43.35.131", "241.223.213.183", "253.116.237.195", "242.66.178.92", "255.185.7.21",…
    ## $ requestport           <int> 37400, 45861, 37986, 57949, 62239, 9273, 17666, 62239, 62239, 62239, 15875, 37677, 2813…
    ## $ backendip             <chr> "253.223.87.30", "252.173.201.86", "250.50.14.107", "247.172.229.147", "253.141.227.189…
    ## $ backendport           <int> 80, 443, 8888, 8888, 8000, 8888, 8888, 8888, 8899, 8888, 8899, 8888, 8888, 8899, 8888, …
    ## $ requestprocessingtime <dbl> 0.000092, 0.000074, 0.000076, 0.000102, 0.000067, 0.000051, 0.000057, 0.000079, 0.00009…
    ## $ backendprocessingtime <dbl> 0.046512, 0.319001, 0.411608, 0.410884, 0.021358, 0.017171, 0.161456, 0.040714, 0.03277…
    ## $ clientresponsetime    <dbl> 0.000068, 0.000074, 0.000070, 0.000068, 0.000040, 0.000032, 0.000042, 0.000044, 0.00004…
    ## $ elbresponsecode       <chr> "200", "500", "500", "500", "200", "200", "500", "200", "200", "200", "200", "200", "20…
    ## $ backendresponsecode   <chr> "200", "200", "404", "200", "200", "200", "404", "403", "200", "200", "200", "404", "50…
    ## $ receivedbytes         <S3: integer64> 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,…
    ## $ sentbytes             <S3: integer64> 2, 30256, 30256, 30256, 52442, 8194, 27952, 1888, 2, 70883, 40191, 1717, 614,…
    ## $ requestverb           <chr> "GET", "GET", "GET", "GET", "GET", "GET", "GET", "GET", "GET", "GET", "GET", "GET", "GE…
    ## $ url                   <chr> "http://www.abcxyz.com:80/jobbrowser/?format=json&state=running&user=fmi7id4", "http://…
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
    ## $ requestprocessingtime <dbl> 0.000089, 0.000087, 0.000084, 0.000079, 0.000120, 0.000081, 0.000090, 0.000091, 0.00009…
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
| R    |        6 | 0.86 | 131 | 0.71 |          13 | 0.34 |       27 | 0.42 |
| Rmd  |        1 | 0.14 |  53 | 0.29 |          25 | 0.66 |       38 | 0.58 |

## Code of Conduct

Please note that this project is released with a [Contributor Code of
Conduct](CONDUCT.md). By participating in this project you agree to
abide by its terms.
