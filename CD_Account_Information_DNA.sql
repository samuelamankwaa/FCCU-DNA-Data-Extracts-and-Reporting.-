Use DataMart
SELECT
c.account_number
, c.member_number
, c.minor_account_type
, c.Minor_Account_Type_Description
-- , p.TAXID,
, CASE WHEN p.TAXID IS NULL THEN 'BUSINESS'
WHEN p.TAXID IS NOT NULL THEN p.TAXID
ELSE NULL END AS 'TAXID'
, 'DefaultPassword' = ''-- ???
, 'Branch' = c.branch_name -- blank in orignal Crystal report
, c.current_balance
, 'DIV_YTD' = c.Dividend_YTD
, c.Interest_Rate
, c.Maturity_Date
, 'DIV_PYR' = c.Dividend_PYR
FROM
   Dep.[CERTIFICATES] c

LEFT JOIN dbo.PERS p
ON p.PERSNBR = c.person_number
    AND p.DL_LOAD_DATE = c.DL_Load_Date

LEFT JOIN dbo.org o 
ON o.ORGNBR = c.organization_number
    AND o.DL_LOAD_DATE = c.DL_Load_Date -- not needed, unless User wants ORG info

WHERE 
c.DL_Load_Date = '2023-10-02' -- data cut date
AND c.account_status != 'Closed' -- active only
ORDER BY c.Account_Number asc, c.member_number asc