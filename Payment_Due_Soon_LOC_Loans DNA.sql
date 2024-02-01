-- DNA
	/*
		XP2 Loan_Type -> DNA Mj Mi Code
			60 - CNS, CL01
			95 - CNS, CL02

		XP2 Warning_Code -> DNA WrnFlag WrnFlagCd
			4 - NOTE? (read memos/alerts before processing any transactions)
			5 - BSWF (Bankruptcy)
			6 - ?? (employee acct - supervisory override)
			8 - COLL (call collections before transaction)
			9 - REPO (repo - call collections)
			10 - ?? (fraud alert)
			18 - ?? (escheat - please contact accouting)
	*/

DECLARE @DL_Load_Date datetime = '2024-01-30';

IF @DL_Load_Date IS NULL
	SELECT @DL_Load_Date = DL_Load_Date
	FROM ID.MonthEnd_DL_Load_Dates
	WHERE sequence = 1;


SELECT 
	EMAIL = ''
	, l.MEMBER_NBR
	, LOAN_NBR = l.ACCTNBR
	, NAME = CONCAT(p.FIRSTNAME, ' ', COALESCE(p.MDLNAME, p.MDLINIT), ' ', p.LASTNAME, ' ', COALESCE(p.SUFFIX, ''))
	, INDIVIDUAL_ID = l.PERS_NBR
	, cell1 = cellp.[1]
	, cell2 = cellp.[2]
	, cell3 = cellp.[3]
	, LOAN_TYPE = l.MAJOR_ACCT_TYPE
	, l.MINOR_ACCT_TYPE
	, TYPE = l.PRODUCT_NAME
	, NEXT_DUE_DATE = al.CURRDUEDATE
	, Phone = cellp.[1]
	, Home_Phone = homep.[1]
	, l.SCHEDULED_PMT
	
FROM 
	Loan.[ALL] l

	INNER JOIN PERS p
		ON l.DL_LOAD_DATE = p.DL_LOAD_DATE
		AND l.PERS_NBR = p.PERSNBR

	INNER JOIN ACCTLOAN al -- to get Next_payment_due date since date in warehouse table used to build Loan.ALL is missing
		ON l.DL_LOAD_DATE = al.DL_LOAD_DATE
		AND l.ACCTNBR = al.ACCTNBR

	CROSS APPLY (
		SELECT Cnt = COUNT(*)
		FROM PERSWRN pw
		WHERE 
			pw.WRNFLAGCD IN ('BSWF', 'COLL', 'REPO')
			AND pw.DL_LOAD_DATE = @DL_Load_Date
			AND l.PERS_NBR = pw.PERSNBR
		) persflag

	CROSS APPLY (
		SELECT Cnt = COUNT(*)
		FROM ACCTWRN aw
		WHERE 
			aw.WRNFLAGCD IN ('NOTE')
			AND aw.DL_LOAD_DATE = @DL_Load_Date
			AND l.ACCTNBR = aw.ACCTNBR
		) acctflag

	CROSS APPLY (
		SELECT 
			[1] = max([1])
			, [2] = max([2])
			, [3] = max([3])
		FROM
			(
				SELECT
					CELLPHONE = CONCAT('(', cp.AREACD, ')', cp.EXCHANGE, '-', cp.PHONENBR)
					, ROW = ROW_NUMBER() OVER(PARTITION BY cp.PERSNBR ORDER BY cp.PHONESEQ ASC, cp.PHONELASTUPDATEDDATE DESC)
				FROM PERSPHONE cp
				WHERE 
					cp.DL_LOAD_DATE = @DL_Load_Date
					AND cp.PERSNBR = l.PERS_NBR
					AND cp.PHONEUSECD = 'CELL'
					AND cp.EXCHANGE <> 0
					AND cp.PHONENBR <> 0
					AND cp.CTRYCD = 'USA'
			) c
		PIVOT
			(
				MAX(CELLPHONE) 
				FOR ROW in ([1], [2], [3])
			) cell
		) cellp

	CROSS APPLY (
		SELECT 
			[1] = max([1])
		FROM
			(
				SELECT
					HOMEPHONE = CONCAT('(', hp.AREACD, ')', hp.EXCHANGE, '-', hp.PHONENBR)
					, ROW = ROW_NUMBER() OVER(PARTITION BY hp.PERSNBR ORDER BY hp.PHONESEQ ASC, hp.PHONELASTUPDATEDDATE DESC)
				FROM PERSPHONE hp
				WHERE 
					hp.DL_LOAD_DATE = @DL_Load_Date
					AND hp.PERSNBR = l.PERS_NBR
					AND hp.PHONEUSECD = 'PER'
					AND hp.EXCHANGE <> 0
					AND hp.PHONENBR <> 0
					AND hp.CTRYCD = 'USA'
			) h
		PIVOT
			(
				MAX(HOMEPHONE) 
				FOR ROW in ([1])
			) home
		) homep

WHERE 
	l.DL_LOAD_DATE = @DL_Load_Date
	AND l.MAJOR_ACCT_TYPE = 'CNS'
	AND l.MINOR_ACCT_TYPE IN ('CL01', 'CL02')
	AND l.ACCT_STATUS = 'ACT'
	AND p.DATEDEATH IS NULL
	AND l.BALANCE > 0
	--AND DATEDIFF(d, '2023-10-01', l.NEXT_PAYMENT_DUE) = 4 -- hardcoded '2023-10-01' for testing -- NULL in the original table
		-- will switch to the above condition after data is updated in the warehouse table
	AND DATEDIFF(d, '2023-10-01', al.CURRDUEDATE) = 4 -- hardcoded for testing
	AND persflag.Cnt = 0
	AND acctflag.Cnt = 0
	--AND l.ACCTNBR NOT IN
	--	(
	--		SELECT ACCTNBR
	--		FROM RW_DELINQUENT_MVIEW delq
	--		WHERE 
	--			delq.DL_LOAD_DATE = @DL_Load_Date
	--			AND delq.AMTDUE > 0
	--	) -- doesn't match with XP2 DelAmt
	AND DATEDIFF(d, l.LAST_UNPAID_PMT_DATE, '2023-10-01') <= 3 -- hardcoded '2023-10-01' for testing
	AND l.SCHEDULED_PMT > 0


ORDER BY l.MEMBER_NBR, l.ACCTNBR
;

