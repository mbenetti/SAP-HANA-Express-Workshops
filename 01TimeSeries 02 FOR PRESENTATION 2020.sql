#########################################################################################################
-- This document was created with the purpose of provide the code snippers necessary to follow the text 
-- processing workshop. A PowerPoint presentation with other learning material will be provide after the
-- session. The code must be run on a SQL query tool for SAP HANA, express edition. For more information 
-- https://developers.sap.com/tutorials/mlb-hxe-tools-sql.html 

Author Benetti Mauro A.
Version: 1.0 15.03.2020
#########################################################################################################

##############################################
# User 01 - Time forcasting with HANA part 2 #
##############################################

--Step 1: SAP HANA Automated Predictive Library
--The SAP HANA Automated Predictive Library (APL) is an Application Function Library (AFL) which lets you use the data mining 
--capabilities of the SAP Predictive Analytics automated analytics engine on your SAP HANA stored data.
--the complete tutorial can be found in https://developers.sap.com/tutorials/hxe-aa-forecast-sql-04.html 

--With the APL, you can create the following types of models to answer your business questions:

--Classification/Regression models
--Clustering models
--Time series analysis models
--Recommendation models
--Social network analysis models

--Step 2: Calling APL functions
--The procedure technique:
--This technique is not only much simpler than the direct technique, but it’s also more efficient and scalable.
--Instead of having to deal with the life cycle of the AFL wrappers and all its companion database objects on a per-call basis, the APL user can directly call APL specific stored procedures which take care of all the AFL details.
--These APL stored procedures are part of the HCO_PA_APL delivery unit which is automatically deployed when installing SAP HANA APL.
--Here is a quick code example with the procedure technique:

SET SESSION 'APL_CACHE_SCHEMA' = 'APL_CACHE';
-- --------------------------------------------------------------------------
-- Create the input/output tables used as arguments for the APL function
-- --------------------------------------------------------------------------
DROP TABLE FUNCTION_HEADER;
CREATE COLUMN TABLE FUNCTION_HEADER LIKE "SAP_PA_APL"."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
INSERT INTO FUNCTION_HEADER values ('key', 'value');

DROP TABLE OPERATION_CONFIG;
CREATE COLUMN TABLE OPERATION_CONFIG LIKE "SAP_PA_APL"."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_DETAILED";
INSERT INTO OPERATION_CONFIG values ('key', 'value');

DROP TABLE TRAINED_MODEL;
CREATE COLUMN TABLE TRAINED_MODEL LIKE "SAP_PA_APL"."sap.pa.apl.base::BASE.T.MODEL_BIN_OID";

DROP TABLE VARIABLE_DESC;
CREATE COLUMN TABLE VARIABLE_DESC LIKE  "SAP_PA_APL"."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
-- -------------------------------------------------------------------------
-- Execute the APL function using its AFL wrapper and the actual input/output tables
-- --------------------------------------------------------------------------
call "SAP_PA_APL"."sap.pa.apl.base::CREATE_MODEL"(FUNCTION_HEADER, OPERATION_CONFIG, 'MYSCHEMA','TRAINING_DATASET', TRAINED_MODEL, VARIABLE_DESC) with overview;

--The procedure is as follow
****************************

--1-Clean previous results
--2-Create input and output table structures
--3-Set the algorithm parameters
--4-Run the algorithm
--5-The results

--1-Clean previous results
**************************
-- --------------------------------------------------------------------------
-- Cleanup SAPL objects
-- --------------------------------------------------------------------------
call sap_pa_apl."sap.pa.apl.base::CLEANUP"(1,?);
-- --------------------------------------------------------------------------
-- Drop function in/out tables, helper tables and views
-- --------------------------------------------------------------------------
drop table apl_cashflow_function_header;
drop table apl_cashflow_operation_config;
drop table apl_cashflow_variable_desc;
drop table apl_cashflow_variable_roles;
drop table apl_cashflow_operation_log;
drop table apl_cashflow_summary;
drop table apl_cashflow_indicators;
drop table apl_cashflow_result;
drop table apl_cashflow_result_extra_pred;
drop view  apl_cashflow_input_data;
drop view  apl_cashflow_input_data_extra_pred;


--2-Create input and output table structures
********************************************

-- --------------------------------------------------------------------------
-- Create generic tables
-- --------------------------------------------------------------------------
create column table apl_cashflow_function_header   like sap_pa_apl."sap.pa.apl.base::BASE.T.FUNCTION_HEADER";
create column table apl_cashflow_operation_config  like sap_pa_apl."sap.pa.apl.base::BASE.T.OPERATION_CONFIG_DETAILED";
create column table apl_cashflow_variable_desc     like sap_pa_apl."sap.pa.apl.base::BASE.T.VARIABLE_DESC_OID";
create column table apl_cashflow_variable_roles    like sap_pa_apl."sap.pa.apl.base::BASE.T.VARIABLE_ROLES_WITH_COMPOSITES_OID";
create column table apl_cashflow_operation_log     like sap_pa_apl."sap.pa.apl.base::BASE.T.OPERATION_LOG";
create column table apl_cashflow_summary           like sap_pa_apl."sap.pa.apl.base::BASE.T.SUMMARY";
create column table apl_cashflow_indicators        like sap_pa_apl."sap.pa.apl.base::BASE.T.INDICATORS";
-- --------------------------------------------------------------------------
-- Create input view and result table
-- --------------------------------------------------------------------------
create view apl_cashflow_input_data            as select cashdate, cash from forecast_cashflow order by cashdate asc;
create view apl_cashflow_input_data_extra_pred as select *              from forecast_cashflow order by cashdate asc;

create column table apl_cashflow_result (
   cashdate daydate
  ,cash     double
  ,kts_1    double
  ,"kts_1_lowerlimit_95%" double
  ,"kts_1_upperlimit_95%" double    
);
create column table apl_cashflow_result_extra_pred  like apl_cashflow_result;


--3-Set the algorithm parameters
********************************

-- --------------------------------------------------------------------------
-- Configuration
-- --------------------------------------------------------------------------
truncate table apl_cashflow_function_header;
insert into apl_cashflow_function_header values ('Oid', '#1');
insert into apl_cashflow_function_header values ('LogLevel', '8');

truncate table apl_cashflow_operation_config;
insert into apl_cashflow_operation_config values ('APL/TimePointColumnName'   , 'CASHDATE'                 , null);
insert into apl_cashflow_operation_config values ('APL/ApplyExtraMode'        , 'Forecasts and Error Bars' , null);
insert into apl_cashflow_operation_config values ('APL/LastTrainingTimePoint' , '2001-12-28', null);
insert into apl_cashflow_operation_config values ('APL/Horizon'               , '21'        , null);

truncate table apl_cashflow_variable_desc;
insert into apl_cashflow_variable_desc values (0, 'CASHDATE' , 'date'     , 'continuous', 1, 1, null, null, null, null);
insert into apl_cashflow_variable_desc values (1, 'CASH'     , 'number'   , 'continuous', 0, 0, null, null, null, null);

truncate table apl_cashflow_variable_roles;
insert into apl_cashflow_variable_roles values ('CASHDATE'  , 'input' , NULL, NULL, '#1');
insert into apl_cashflow_variable_roles values ('CASH'      , 'target', NULL, NULL, '#1');

select * from apl_cashflow_operation_config;

--4-Run the algorithm
*********************

-- --------------------------------------------------------------------------
-- Clean result tables
-- --------------------------------------------------------------------------
truncate table apl_cashflow_result;
truncate table apl_cashflow_operation_log;
truncate table apl_cashflow_summary;
truncate table apl_cashflow_indicators;
-- --------------------------------------------------------------------------
-- Execute the APL function to train the model with the dataset
-- --------------------------------------------------------------------------
call sap_pa_apl."sap.pa.apl.base::FORECAST" (
    apl_cashflow_function_header
  , apl_cashflow_operation_config
  , apl_cashflow_variable_desc
  , apl_cashflow_variable_roles
  , current_schema, 'APL_CASHFLOW_INPUT_DATA'
  , current_schema, 'APL_CASHFLOW_RESULT'
  , apl_cashflow_operation_log
  , apl_cashflow_summary
  , apl_cashflow_indicators
) with overview;

--5-The results
***************

--Check the logs, indicators, summary and results
--The operation log. When performing an APL operation, especially training or applying a model, 
--the Automated Analytics engine produces status/warning/error messages.
--These messages are returned from an APL function through an output database table.

select * from apl_cashflow_operation_log;

--If you look at the output you will find interesting about the overall modeling process :


