SELECT 
'InternalAccountNumber' = s.SHARE_NBR
, 'ExternalAccountNumber' = cast(s.member_nbr as varchar) + '-' + cast(s.share_nbr as varchar)
, 'ProductTypeIndicator' = p.PRODUCT_ITEM_ID
, 'Account Description' = p.product_name
, 'InternalCIF' = s.member_nbr
, 'ExternalCIF' = i.tin
, 'DefaultPassword' = ''-- ???
, 'Branch' = b.NAME  -- blank in the report
, 'BALANCE' = s.balance
, 'DIV_YTD' = s.DIV_YTD
, 'RATE' = c.rate
, 'MAT_DATE' = c.MAT_DATE
, 'DIV_PYR' = s.DIV_PYR
FROM dbo.SHARE s
    INNER JOIN dbo.product p
    ON p.FXP_TYPE_NBR = s.SHARE_TYPE

    INNER JOIN dbo.membershipparticipant mp
    ON mp.member_nbr = s.member_nbr
        AND mp.dl_load_Date = s.dl_load_Date
        AND mp.participation_type = 101

    INNER JOIN dbo.individual i
    ON i.individual_id = mp.individual_id
        AND i.dl_load_Date = mp.dl_load_Date

    INNER JOIN dbo.certificate c
    ON c.member_nbr = s.member_nbr
        AND c.share_nbr = s.share_nbr
        AND c.dl_load_Date = s.dl_load_Date

    INNER JOIN dbo.BRANCH b
    ON b.BRANCH_NBR = s.MEMBER_BRANCH

WHERE 
s.DL_LOAD_DATE = '2023-10-01' -- data cut date?

    AND s.class = 2 -- cert
    AND s.CLOSED != -1 -- not close
    AND p.PRODUCT_CATEGORY_CODE = 1 -- share
ORDER BY s.MEMBER_NBR asc, s.SHARE_NBR asc