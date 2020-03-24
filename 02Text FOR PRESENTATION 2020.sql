#########################################################################################################
-- This document was created with the purpose of provide the code snippers necessary to follow the text 
-- processing workshop. A PowerPoint presentation with other learning material will be provide after the
-- session. The code must be run on a SQL query tool for SAP HANA, express edition. For more information 
-- https://developers.sap.com/tutorials/mlb-hxe-tools-sql.html 

Author Benetti Mauro A.
Version: 1.0 15.03.2020
#########################################################################################################

#############################################
#- User 02 - Text Analysis with HANA part 1 #
#############################################

-- Simple Text Analysis on Existing Data

CREATE COLUMN TABLE "A_MYTABLE2"
(
ID INTEGER PRIMARY KEY, 
STRING nvarchar(200)
)
;

-- Insert some values

INSERT INTO "A_MYTABLE2" VALUES (1, 'Bob likes working at SAP.');

-- The next line create a full text index using the first configuration (linguistic analysis basic)

CREATE FULLTEXT INDEX myindex ON "A_MYTABLE2" ("STRING")
CONFIGURATION 'LINGANALYSIS_BASIC'
TEXT ANALYSIS ON;

--Open the content of the $TA_MYINDEX and A_MYTABLE2
SELECT * FROM "$TA_MYINDEX" ORDER BY ID, TA_COUNTER; --or with the right click of your mouse over the table.

DELETE FROM "A_MYTABLE2"; --only delete the content

INSERT INTO "A_MYTABLE2" VALUES (1, 'Bob likes working at SAP. Bob likes New York.');

INSERT INTO "A_MYTABLE2" VALUES (2, 'Peter likes play football and Markus will work on Hana Express.');
-- you can see that the index update automatically, do not close the tab please, we will use it later on

DROP FULLTEXT INDEX myindex; -- delete the index to create a new one, but with a different configuration

CREATE FULLTEXT INDEX myindex ON "A_MYTABLE2" ("STRING")
CONFIGURATION 'LINGANALYSIS_STEMS'
TEXT ANALYSIS ON;

--Open the content of the $TA_MYINDEX and A_MYTABLE2, do not close the tab please, we will use it later on.

DROP FULLTEXT INDEX myindex;

CREATE FULLTEXT INDEX myindex ON "A_MYTABLE2" ("STRING")
CONFIGURATION 'LINGANALYSIS_FULL'
TEXT ANALYSIS ON;

--Open the content of the $TA_MYINDEX and A_MYTABLE2. Now we can compare the different results for the different configurations.

DROP FULLTEXT INDEX myindex;

CREATE FULLTEXT INDEX myindex ON "A_MYTABLE2" ("STRING")
CONFIGURATION 'EXTRACTION_CORE'
TEXT ANALYSIS ON;

--Open the content of the $TA_MYINDEX and A_MYTABLE2, do not close the tab please, we will use it later on.

DROP FULLTEXT INDEX myindex;

CREATE FULLTEXT INDEX myindex ON "A_MYTABLE2" ("STRING")
CONFIGURATION 'EXTRACTION_CORE_VOICEOFCUSTOMER'
TEXT ANALYSIS ON;

DROP FULLTEXT INDEX myindex;

CREATE FULLTEXT INDEX myindex ON "A_MYTABLE2" ("STRING")
CONFIGURATION 'GRAMMATICAL_ROLE_ANALYSIS'
TEXT ANALYSIS ON;

-- This is how you create a table with the result of the index created.

--CREATE COLUMN TABLE "TEXT" AS (SELECT "ID", "TA_COUNTER", "TA_PARENT", "TA_TOKEN","TA_TYPE" FROM "$TA_MYINDEX" ORDER BY ID, TA_COUNTER);

-- SELECT * FROM "$TEXT" ORDER BY ID, TA_COUNTER;

DROP FULLTEXT INDEX myindex;
DROP TABLE "TEXT";
DROP TABLE "A_MYTABLE2";

######################
-- Tweeter analysis
######################

CREATE FULLTEXT INDEX TWANALYSIS2 ON "Twitter2" ("text")
CONFIGURATION 'EXTRACTION_CORE_VOICEOFCUSTOMER'
TEXT ANALYSIS ON;

SELECT TA_COUNTER,TA_TOKEN,TA_TYPE FROM "$TA_TWANALYSIS2" ORDER BY TA_COUNTER ASC;

SELECT * FROM "$TA_TWANALYSIS2" WHERE TA_PARENT='4' ORDER BY TA_COUNTER ASC;
SELECT * FROM "$TA_TWANALYSIS2" WHERE TA_COUNTER='4';
SELECT TA_COUNTER,TA_TOKEN,TA_TYPE FROM "$TA_TWANALYSIS2" WHERE TA_PARENT='4' ORDER BY TA_COUNTER ASC;

DROP FULLTEXT INDEX TWANALYSIS2

#################################################
#- User 02 - Document store and text processing #
#################################################

--In order to perform Text Analysis on the JSON documents, you need to copy the data to a columnar table, 
--and enable fuzzy text search on its index. First, you need to create the table. Perform the following 
--SQL statement:

--Step 1: Create table for fuzzy search
***************************************

create column table food_analysis
(
	name nvarchar(64),
	description text FAST PREPROCESS ON FUZZY SEARCH INDEX ON
);

--This statement will create a table food_analysis with two fields; a field name for the name of the food, 
--and a field description which will have fuzzy text search enabled.

--Step 2: Copy from Document Store to Table
*******************************************

--In the previous step you created a columnar table. In this step, you will populate it with the name and 
--description fields from the JSON documents in the Document Store. Perform the following SQL statement:

insert into food_analysis
with doc_store as (select "name", "description" from food_collection)
select doc_store."name" as name, doc_store."description" as description
from doc_store;

--This statement will insert into table food_analysis the data from fields name and description which come 
--from the food_collection collection in the Document Store. To check whether the data has been copied properly, 
--execute the statement select * from food_analysis and see if the name and description fields are properly filled:

select * from food_analysis

--Step 3: Perform Text Analysis. Fuzzy search and similarity
************************************************************

--With the data enabled for Text Analysis, you can now try out some queries. Perform the following query:

select  name, score() as similarity, TO_VARCHAR(description)
from food_analysis
where contains(description, 'nuts', fuzzy(0.5,'textsearch=compare'))
order by similarity desc

--If you look at the actual texts in the description field, you may notice some may contain the word nuts, but others won’t.
--Another surprising result may be the appearance of the Common beet entry. However, if you look into its description, 
--it is said that: [...] The fruit is a cluster of hard nutlets. ultimately it makes sense for the common beet to show up after all.
--In this example, the option textSearch does a full-text search. There are many more options available for fuzzy text search, 
--such as similarCalculationMode which controls how the similarity of two strings are calculated.

--Try the following query for similarity:

select  name, score() as similarity, TO_VARCHAR(description)
from food_analysis
where contains(description, 'europe', fuzzy(0.7,'similarCalculationMode=symmetricsearch'))
order by similarity desc

--Step 4: Perform Linguistic Text Analysis
******************************************

--In the previous example, you performed a couple of queries using fuzzy search. It is also possible to perform linguistic analysis.
--Since you cannot have two indices on the same single column, let’s create a new table:

create column table food_sentiment
(
	name nvarchar(64) primary key,
	description nvarchar(2048)
);

--Similar to the other columnar table, you need to import the JSON documents again:

insert into food_sentiment
with doc_store as (select "name", "description" from food_collection)
select doc_store."name" as name, doc_store."description" as description
from doc_store;

--Now, you create a new index with full text analysis capabilities on the description column:

CREATE FULLTEXT INDEX FOOD_SENTIMENT_INDEX ON "FOOD_SENTIMENT" ("DESCRIPTION")
CONFIGURATION 'GRAMMATICAL_ROLE_ANALYSIS'
LANGUAGE DETECTION ('EN')
SEARCH ONLY OFF
FAST PREPROCESS OFF
TEXT MINING OFF
TOKEN SEPARATORS ''
TEXT ANALYSIS ON;

--This will create the index FOOD_SENTIMENT_INDEX, but it will also create a Text Analysis table $TA_FOOD_SENTIMENT_INDEX.
--If you query that table with:

select * from "$TA_FOOD_SENTIMENT_INDEX"

--…you get a full breakdown of each word, its type, its normalized form and stem, if applicable:


##########################
# TEXT MINING. PART 2    #
##########################


-- INITIAL SYSTEM SET UP - data import
/*********************************************************/
-- The exercises use some data which is provided by the National Science foundation in the US.
-- This data was imported to your schema via flat file upload. In total contains 5066 publications. 
-- The field for abstract is LOB type,  this type is used to store a large amount of data such as text documents and images. 
-- The current maximum size for an LOB on SAP HANA is 2GB.


--The Basics: Full-Text Indexing and the Contains Predicate
/********************************************************/
-- Create a "plain vanilla" fulltext index on the TITLE column

CREATE FULLTEXT INDEX "FTI_AWARD2_TITLE" ON "AWARD2"("TITLE") 
SEARCH ONLY OFF;

--without the option TEXT ANALYSIS ON we create the index but not the table.

-- This fulltext index enables full-text search, using the CONTAINS predicate
SELECT "TITLE","ABSTRACT" FROM "AWARD2" WHERE CONTAINS("TITLE", 'carbon');

-- Later you can try following search examples by un-commenting the individual WHERE statements

SELECT SCORE() AS "SCO", HIGHLIGHTED("TITLE") AS HL, "PROGRAM", "AWARD_DATE", * 
	FROM AWARD2 
	WHERE CONTAINS("TITLE", 'design')
--	WHERE CONTAINS("TITLE", 'design *faces')
--	WHERE CONTAINS("TITLE", 'design ?onic')
--	WHERE CONTAINS("TITLE", '"interface design"')
--	WHERE CONTAINS("TITLE", 'NEAR((interface design), 2, false)')
--	WHERE CONTAINS("TITLE", 'carbon OR design') AND PROGRAM = 'Chemical Catalysis'
--	WHERE CONTAINS("TITLE", 'carbon OR design') AND CONTAINS("PROGRAM", 'chemicle catalisys', FUZZY(0.8))
--	WHERE CONTAINS(("TITLE", "PROGRAM"), 'design chemicle catalisys', FUZZY(0.8))
--	WHERE CONTAINS(("TITLE", "PROGRAM", "AWARD_DATE"), 'design chemicle catalisys 2016-08-20', FUZZY(0.7))
	ORDER BY SCO DESC
	LIMIT 10;

-- To leverage LINGUISTIC search we need to turn off "FAST PREPROCESS". Text is now linguistically analyzed. Not only return the exact match.

DROP FULLTEXT INDEX "FTI_AWARD2_TITLE";

CREATE FULLTEXT INDEX "FTI_AWARD2_TITLE" ON "AWARD2"("TITLE")
	FAST PREPROCESS OFF SEARCH ONLY OFF;

-- Now searching for "design process" also finds "design processing" and "designed"

SELECT SCORE() AS "SCO", "TITLE", HIGHLIGHTED ("TITLE") AS HL, LANGUAGE("TITLE"), INDEXING_ERROR_MESSAGE("TITLE"), INDEXING_ERROR_CODE("TITLE"), * 
	FROM "AWARD2" 
	WHERE CONTAINS("TITLE", 'design process', LINGUISTIC)
	ORDER BY SCO DESC
	LIMIT 10;

DROP FULLTEXT INDEX "FTI_AWARD2_TITLE";

##############################################################
-- TEXT MINING WITH AWARDS - GET TERMS FROM ALL DOCUMENTS D->W
/***********************************************************/

-- Let's create another fulltext index on the ABSTRACT column - this time turning on text analysis to extract entities.

--DROP FULLTEXT INDEX "AWARDS_IDX";

CREATE FULLTEXT INDEX "FTI_AWARD_ABSTRACT" ON "AWARD"("ABSTRACT")
	TEXT ANALYSIS ON CONFIGURATION 'EXTRACTION_CORE';

-- Let's take a look at the results of text analysis process which we ran on the ABSTRACT data.
-- The text analysis results are store in a table which was created by SAP HANA automatically:

SELECT * FROM "$TA_FTI_AWARD_ABSTRACT" ORDER BY "ID", "TA_COUNTER" ASC;

-- Let's look at the different semantic types being extracted by text analysis:

SELECT "TA_TYPE", COUNT(*) AS C FROM "$TA_FTI_AWARD_ABSTRACT" GROUP BY "TA_TYPE" ORDER BY C DESC;

-- The most repeated noun_group is "graduate students" and "undergraduate students"

SELECT "TA_TOKEN", COUNT(*) AS C FROM "$TA_FTI_AWARD_ABSTRACT" WHERE "TA_TYPE" = 'NOUN_GROUP' GROUP BY "TA_TOKEN" ORDER BY C DESC;
-- Use open preview to do analysis of the data. The most common type is the noun_group



-- Let's use the text analysis data to generate some key words for the documents, using basic TFIDF

SELECT DISTINCT "ID", COALESCE("TA_NORMALIZED", lower("TA_TOKEN")) "TOK", "TA_TYPE" AS "TYP"
FROM "$TA_FTI_AWARD_ABSTRACT"


DROP FULLTEXT INDEX "FTI_AWARD_ABSTRACT";

--TEXT MINING WITH AWARDS - GET RELEVANT DOCUMENTS W->D
/*******************************************************/

/*Discover the top-ranked relevant documents based on an input term.*/

/*Exercise Description
.- Create fulltext index and text mining index from reference document set
.- Monitor the progress and status of text processing
.- Execute the text mining function TM_GET_RELEVANT_DOCUMENTS with the input term “enzyme”
.- Show top-ranked documents from the reference documentation set relevant to “enzyme”
*/

--SET SCHEMA BENETTIM

--DROP FULLTEXT INDEX "AWARDS_IDX";

CREATE FULLTEXT INDEX "AWARDS_IDX" ON "AWARD"(ABSTRACT)
FAST PREPROCESS OFF
TEXT MINING ON;

-- In text mining configuration 3 tables are created with the information needed to perform a text mining analysis.

SELECT "ID","TITLE","RANK","SCORE" FROM TM_GET_RELEVANT_DOCUMENTS (
TERM 'enzyme' 
	SEARCH "ABSTRACT" 
	FROM "AWARD"
	RETURN TOP 16 ID, TITLE
) AS T;

-- The statement return the top 16 documents related to the term enzyme.


-- TEXT MINING WITH AWARDS - GET RELATED DOCUMENTS D->D
/******************************************************/

/*In this exercise, discover the top-ranked related documents based on an input document found already in the previous reference collection./*

/*Exercise Description
.- View the initial input document from the reference document set about enzymes
.- Execute the text mining function TM_GET_RELATED_DOCUMENTS with the input document about enzymes
.- Show top-ranked documents from the reference documentation set related to the input document about enzymes
*/

SELECT "ID","RANK","SCORE" FROM TM_GET_RELATED_DOCUMENTS (
DOCUMENT (
SELECT "ABSTRACT"
FROM "AWARD"
WHERE "ID" = '1616851' )
SEARCH DISTINCT "ABSTRACT" FROM "AWARD"
RETURN PRINCIPAL COMPONENTS 2 CORRELATION
TOP 20 ID
) AS T;

-- Let have a look at the most and the least related document
SELECT "ID","TITLE", "ABSTRACT" FROM "AWARD"
WHERE ID = '1615415';

SELECT "ID","TITLE", "ABSTRACT" FROM "AWARD"
WHERE ID = '1608147';

--/**************************************** Another example to do it later

SELECT "ID","TITLE", "ABSTRACT" FROM "AWARD"
WHERE ID = '1624296';

SELECT "ID","SCORE" FROM TM_GET_RELATED_DOCUMENTS (
DOCUMENT (
SELECT "ABSTRACT"
FROM "AWARD"
WHERE "ID" = '1624296' )
SEARCH DISTINCT "ABSTRACT" FROM "AWARD"
RETURN PRINCIPAL COMPONENTS 2 CORRELATION
TOP 20 ID
) AS T;

SELECT "ID","TITLE", "ABSTRACT" FROM "AWARD"
WHERE ID = '1622991';

SELECT "ID","TITLE", "ABSTRACT" FROM "AWARD"
WHERE ID = '1623299';

/*Notice this text mining function shows the top ranked documents related to the initial input document
already found in the reference documentation set. The initial input document is also returned with a score 
of 1.0, since it’s a perfect match for itself.
*/

-- TEXT MINING WITH AWARDS - GET RELATED DOCUMENTS WITH NEW DOCUMENT NEW TEXT D->D
--/*******************************************************************************/

/*In this exercise, discover the top-ranked related documents based on a new (previously unseen) input
document.
Exercise Description:

.- Execute the text mining function TM_GET_RELATED_DOCUMENTS with a new input document
.- Show top-ranked documents from the reference documentation set related to the new input document
*/

SELECT * FROM TM_GET_RELATED_DOCUMENTS (
DOCUMENT 'The molecule known as coenzyme A plays a key role in cell metabolism by regulating the actions of nitric oxide. Coenzyme A sets into motion a process known as protein nitrosylation, which unleashes nitric oxide to alter the shape and function of proteins within cells to modify cell behavior. The purpose of manipulating the behavior of cells is to tailor their actions to accommodate the everchanging needs of the body’s metabolism.'
SEARCH "ABSTRACT" FROM "AWARD"
RETURN TOP 16 ID, TITLE
) AS T;

/*Notice this shows the top ranked documents related to a new input document not found in the reference document set. */

-- TEXT MINING WITH AWARDS - GET RELEVANT TERMS D-> W
--/**************************************************/

/*Objective
In this exercise, discover the top-ranked relevant terms (key phrases) that describe a document.
Exercise Description
.- Execute the text mining function TM_GET_RELEVANT_TERMS with an input document already found in
the reference document set
.-Show top-ranked relevant terms from the reference documentation set that describe the input document*/


SELECT "RANK","TERM","TERM_TYPE","SCORE", "TERM_FREQUENCY","DOCUMENT_FREQUENCY" FROM TM_GET_RELEVANT_TERMS (
DOCUMENT IN FULLTEXT INDEX WHERE "ID" = '1638348'
SEARCH "ABSTRACT" FROM "AWARD"
RETURN TOP 16
) AS T;

--We can observe that system/s appears about 3000 times, but is not relevant for this document because is a word used in many documents.

-- TEXT MINING WITH AWARDS - GET RELATED TERMS W -> W
/****************************************************/

/*In this exercise, discover the top-ranked related terms based on co-occurrence to an input term.
Exercise Description:
.- Execute the text mining function TM_GET_RELATED_TERMS with the input term “enzyme”
.- Show top-ranked terms from the reference documentation set related to the input term “enzyme”
*/

SELECT "RANK","TERM","TERM_TYPE","SCORE", "TERM_FREQUENCY","DOCUMENT_FREQUENCY"
FROM TM_GET_RELATED_TERMS (
	TERM 'enzyme'
	SEARCH "ABSTRACT" FROM "AWARD"
	RETURN TOP 16
) AS T;

/*This text mining function shows the top ranked related terms to the input term "enzyme"
*/

-- TEXT MINING WITH AWARDS - GET SUGGESTED TERMS W -> W
/*******************************************************/

/*Objective
In this exercise, discover the top-ranked terms matching an initial substring.
Exercise Description
.- Execute the text mining function TM_GET_SUGGESTED_TERMS with the input substring “enz”
.- Show top-ranked suggested terms from the reference documentation set matching the input substring “enz”
*/

SELECT "RANK","TERM","TERM_TYPE","SCORE", "TERM_FREQUENCY","DOCUMENT_FREQUENCY" 
FROM TM_GET_SUGGESTED_TERMS (
	TERM 'enz'
	SEARCH "ABSTRACT" FROM "AWARD"
	RETURN TOP 5
) AS T;

/*Notice this text mining function shows the top ranked SUGGESTED terms to the input substring "enz" not the related ones.*/


/*********************************************************/
-- TEXT MINING WITH AWARDS - CATEGORIZATION
--/*********************************************************/

/*Objective :
In this exercise, provide an input document in order to determine the document categories from the
reference collection that are most similar to the input document based on the terms used.
Exercise Description
.- Execute the text mining function TM_CATEGORIZE_KNN with a new input document
.- Show top most-similar categories from the reference documentation set matched to the new input document
*/

SELECT * FROM TM_CATEGORIZE_KNN (
	DOCUMENT 'The molecule known as coenzyme A plays a key role in cell metabolism by regulating the actions of nitric oxide. Coenzyme A sets into motion a process known as protein nitrosylation, which unleashes nitric oxide to alter the shape and
	function of proteins within cells to modify cell behavior. The purpose of manipulating the behavior of cells is to tailor their actions to accommodate the everchanging needs of the body’s metabolism.'
	SEARCH NEAREST NEIGHBORS 15 "ABSTRACT" FROM "AWARD"
	RETURN TOP 16 PROGRAM FROM "AWARD"
) AS T;

/*Notice the categorization function determines the top categories from the most similar reference
documents and does a weighted comparison by adding and normalizing the similarities for each category value.
*/


/**********************
--//END OF THE DOCUMENT 
/**********************