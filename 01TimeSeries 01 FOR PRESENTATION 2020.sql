#########################################################################################################
-- This document was created with the purpose of provide the code snippers necessary to follow the text 
-- processing workshop. A PowerPoint presentation with other learning material will be provide after the
-- session. The code must be run on a SQL query tool for SAP HANA, express edition. For more information 
-- https://developers.sap.com/tutorials/mlb-hxe-tools-sql.html 

Author Benetti Mauro A.
Version: 1.0 15.03.2020
#########################################################################################################

##############################################
# User 01 - Time forcasting with HANA part 1 #
##############################################


--The datasets archive structure for the Sample Time Series is the following:

|--sample_time_series_3.3.1_en-us_production.zip
   |-- Time series.zip
   |   |-- Time series
   |       |-- CashFlows.csv
   |       |-- KxDesc_CashFlows.csv
   |       |-- Lag1AndCycles.csv
   |       |-- Lag1AndCyclesAndWn.csv
   |       |-- R_ozone-la.csv
   |       |-- TrendAndCyclic.csv
   |       |-- TrendAndCyclicAnd_4Wn.csv
   |       |-- TrendAndCyclicAndWn.csv
   |-- metadata.xml

--Cash Flows
************
--The Cash Flows file (CashFlows.csv) presents daily measures of cash flows 
--from January 2, 1998 to September, 30 1998. Each observation is characterized by 25 variables.
--In this scenario, you are an executive of a financial entity that manages cash-flows. 
--Your role is to make sure that credits are available with the correct amount at the correct date 
--to provide the best management possible of your financial flows.

--Los Angeles Ozone
*******************
--The Los Angeles Ozone file (R_ozone-la.csv) presents monthly averages of hourly ozone (O3) 
--readings in downtown Los Angeles from 1955 to 1972.
--Each observation is characterized by 2 variables, a time and an average of the hourly ozone readings for the month.

--The purpose of this scenario is to confirm the decreasing trend of the ozone rate by predicting the next 18 months and 
--describing the different signal elements based on the ozone rate.

-- This data was imported to your schema via flat file upload. In total contains some of the datasets in the file provided in 
--the zip file. 

--Time series analysis
**********************
--Connect to the HXE tenant using the ML_USER user credentials and execute the following SQL statement to check the 
--number of rows:

select 'cashflow' as "TABLE", count(1) as "COUNT" from "ML_DATA"."FORECAST_CASHFLOW" 
union all
select 'ozone'                    as "TABLE", count(1) as "COUNT" FROM forecast_ozone

--Table name	Row count
--cashflow	    272
--ozone 	    204

--Visualize the data

select cashdate, cash from forecast_cashflow order by cashdate asc;

--As you can visually notice, the signal includes:
--steep peaks a repeating pattern but with irregular gaps/intervals
--the signal trend tends to slightly decline then rise at the end
--Also, you can notice that the peaks happens at certain intervals, 
--and the data include some kind of trend that is slightly going down then rising.

--Dates & intervals

select 'max' as indicator, to_varchar(max(cashdate)) as value
from   forecast_cashflow union all
select 'min'             , to_varchar(min(cashdate))
from   forecast_cashflow union all
select 'delta days'      , to_varchar(days_between(min(cashdate), max(cashdate)))
from   forecast_cashflow union all
select 'count'           , to_varchar(count(1))
from   forecast_cashflow

--indicator	    value
--max	        2002-01-31
--min	        2001-01-02
--delta days	394
--count	        271

--As you can notice, you have 272 data points spread across 394 days. This implies that data is not available on a 
--daily basis.This may have an impact on the way some algorithms work.
--Now let’s check the interval distribution using the following SQL:


select   interval, count(1) as count
from (
    select   days_between (lag(cashdate) over (order by cashdate asc), cashdate) as interval
    from     forecast_cashflow
    order by cashdate asc
)
where    interval is not null
group by interval;

The result should be:

--interval	count
--  1	    211
--  3	    52
--  4	    2
--  2	    4
--  5	    1
--  6	    1

--Most data points are provided on a daily basis when others have a:
--2 days interval most likely caused by a bank holiday during the week
--3 days interval most likely because of weekends
--4, 5 or 6 days interval most likely because of a bank holiday next to a weekend or other special events

--Generic statistics
--Now, let’s have a look at some generic statistical elements using the following SQL:

select 'max' as indicator , round(max(cash)) as value    from forecast_cashflow union all
select 'min'              , round(min(cash))             from forecast_cashflow union all
select 'delta min/max'    , round(max(cash) - min(cash)) from forecast_cashflow union all
select 'avg'              , round(avg(cash))             from forecast_cashflow union all
select 'median'           , round(median(cash))          from forecast_cashflow union all
select 'stddev'           , round(stddev(cash))          from forecast_cashflow

--The result should be:
--indicator	value
--max	    24659
--min	    1579
--min/max	23079
--avg	    5361
--median	4434
--stddev	3594

--Ozone
*******
--As stated earlier, the Los Angeles Ozone dataset presents monthly averages of hourly ozone (O3) readings in downtown Los Angeles 
--from 1955 to 1972. Each observation is characterized by 2 variables, a time and an average of the hourly ozone readings for the month.

--Visualize the data

select time, reading from forecast_ozone order by time asc;

--Dates & intervals
--As the ozone reading value is provided for a certain date, let’s have a look at date values using the following SQL:

select 'max' as indicator, to_varchar(max(time)) as value
from   forecast_ozone union all
select 'min'             , to_varchar(min(time))
from   forecast_ozone union all
select 'delta days'      , to_varchar(days_between(min(time), max(time)))
from   forecast_ozone union all
select 'count'           , to_varchar(count(1))
from   forecast_ozone

--As you can notice, you have 204 data points spread across 16 years. This implies that data is available on a monthly basis.
--Now let’s check the date value interval distribution using the following SQL:

select   interval, count(1) as count
from (
    select   days_between (lag(time) over (order by time asc), time) as interval
    from     forecast_ozone
    order by time asc
)
where    interval is not null
group by interval

--The result should be:
--interval	count
--  31	    118
--  28	    13
--  30	    68
--  29  	4

--The fact that every month don’t have the same duration may impact certain algorithms leveraging the date information in the model.

--Generic statistics
********************
--Now, let’s have a look at some additional statistical elements using the following SQL:

select 'max' as indicator , round(max(reading)) as value       from forecast_ozone union all
select 'min'              , round(min(reading))                from forecast_ozone union all
select 'delta min/max'    , round(max(reading) - min(reading)) from forecast_ozone union all
select 'avg'              , round(avg(reading))                from forecast_ozone union all
select 'median'           , round(median(reading))             from forecast_ozone union all
select 'stddev'           , round(stddev(reading))             from forecast_ozone

--The result should be:
--indicator	value
--max	    8.13
--min	    1.17
--min/max	6.96
--avg	    3.72
--median	3.67
--stddev	1.41

--As you can notice the average and median values are in the same range of values.

--Data Distribution
--Now let’s have a look at the data distribution using the NTILE function.
--The following SQL will partition the data into 10 groups and get the same generic statistics as before but for each group:

with data as (
    select ntile(10) over (order by reading asc) as tile, reading
    from   forecast_ozone
    where  reading is not null
)
select tile
    , round(max(reading), 2)                        as max
    , round(min(reading), 2)                        as min
    , round(max(reading) - min(reading), 2)         as "delta min/max"
    , round(avg(reading), 2)                        as avg
    , round(median(reading), 2)                     as median
    , round(abs(avg(reading) - median(reading)), 2) as "delta avg/median"
    , round(stddev(reading), 2)                     as stddev
from     data
group by tile


