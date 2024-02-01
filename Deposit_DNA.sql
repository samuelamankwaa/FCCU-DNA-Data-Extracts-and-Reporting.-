-- minor_account_type_description	minor_account_type
-- Non-Profit (Association Saving)	SB02: 562
-- Business Basic Checking	        BC01: 4,943
-- Business Growth Checking	        BC02: 136
-- Business Money Market Checking	BC03: 342
-- Business Savings	                SB01: 5,164
-- Non-Profit Checking	            BC04: 4,963
Use DataMart
SELECT 
a.person_number
, a.organization_number
, a.Account_Number
, a.member_number
,'DEPOSIT' as PRODUCT
, a.minor_account_type
, a.major_account_type_category
,'BUSINESS' as PRODUCT_LINE
, a.major_account_type
,CASE WHEN a.major_account_type = 'CK' THEN 'CHECKING'
WHEN a.major_account_type = 'SAV' THEN 'SAVINGS'
WHEN a.major_account_type = 'TD' THEN 'CD'
ELSE NULL
END AS 'PRODUCT_TYPE'
, a.minor_account_type_description
-- ,'AVG_MONTHLY_BAL_DATE' = -- As of date for the average monthly balance amounts (always a month end date)
,'AVG_DAILY1_BAL' = a.average_daily_balance1 -- Average daily balance as of AVG_DAILY_BAL_DATE
,'AVG_DAILY_BAL_DATE' = NULL --As of date for the average daily balance (always a month end date)
,'AVG_DAILY2_BAL' = NULL --Average daily balance one month prior
-- ,'AVG_MONTHLY2_BAL' = -- Average monthly balance for one month prior
-- ,'AVG_MONTHLY3_BAL' = --Average monthly balance for two months prior
,'AVG_DAILY3_BAL' = NULL --Average daily balance two months prior
,'BACKUP_WHLD_CODE' = NULL -- ??
, a.current_balance
, a.close_date
, a.account_status
,'DEP_CNT_YTD' = NULL -- ??
,'DIV_LAST_DATE' = NULL -- ??
,'DIV_LAST_PAID' = NULL -- ??
,'DIV_PYR' = a.dividend_PYR
,'DIV_YTD' = a.DIVIDEND_YTD
,'LAST_CUST_CONT_DATE' = a.Last_Contact_Date
,'LAST_REG_D_UPDATE_DATE' = NULL --??
, 'OPEN_AMT' = a.open_amount
, a.open_date
, a.branch_name
,'FEE_AMT_REF_LAST_30_DAYS' = NULL --??
,'FEE_AMT_COLL_LAST_30_DAYS' = NULL --??
,'NEG_BAL_CNT_LAST_30_DAYS' = NULL --??
,'HIGH_NEG_BAL_LAST_30_DAYS' = NULL --??
,'OPEN_BY_OPR_NBR' = NULL -- no historical data in DNA
,'OPEN_AT_BRANCH_NBR' = NULL -- no historical data in DNA
,'REOPEN_BY_OPR_NBR' = NULL -- no historical data in DNA
,'REOPEN_AT_BRANCH_NBR' = NULL -- no historical data in DNA
 FROM Dep.[ALL] a 

WHERE a.dl_load_date = '2023-10-02' -- test dl load date
AND a.major_account_type_category = 'DEP' -- only deposits
AND a.minor_account_type in ('BC01','BC02','BC03','BC04','SB01', 'SB02') -- Business CK & SAV

ORDER BY a.member_number ASC, a.Account_Number ASC