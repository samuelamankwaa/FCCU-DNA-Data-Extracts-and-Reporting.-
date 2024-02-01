DECLARE @DL_Load_Date datetime = '2024-01-30';

IF @DL_Load_Date IS NULL
	SELECT @DL_Load_Date = DL_Load_Date
	FROM ID.MonthEnd_DL_Load_Dates
	WHERE sequence = 1;



SELECT 
	l.DL_LOAD_DATE
	, EMAIL = ''
	, l.SCHEDULED_PMT
	, l.MEMBER_NBR
	, LOAN_NBR = l.ACCTNBR
	, NAME = CONCAT(p.FIRSTNAME, ' ', COALESCE(p.MDLNAME, p.MDLINIT), ' ', p.LASTNAME, ' ', COALESCE(p.SUFFIX, ''))
	, cell1 = cellp.[1]
	, cell2 = cellp.[2]
	, cell3 = cellp.[3]
	, Phone = cellp.[1]
	, LOAN_TYPE = l.MAJOR_ACCT_TYPE
	, l.MINOR_ACCT_TYPE
	, TYPE = l.PRODUCT_NAME
	, NEXT_DUE_DATE = al.CURRDUEDATE
	, Home_Phone = homep.[1]

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
			, [2] = max([2])
			, [3] = max([3])
		FROM
			(
				SELECT
					CELLPHONE = CONCAT('(', hp.AREACD, ')', hp.EXCHANGE, '-', hp.PHONENBR)
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
				MAX(CELLPHONE) 
				FOR ROW in ([1], [2], [3])
			) home
		) homep

WHERE
	l.DL_LOAD_DATE = @DL_Load_Date
	AND p.DATEDEATH IS NULL
	AND l.ACCT_STATUS = 'ACT'
	AND l.MAJOR_ACCT_TYPE = 'CNS'
	AND l.MINOR_ACCT_TYPE IN ('IN03', 'CS02', 'IN01', 'IN02', 'CS03', 'CS01', 'IL02', 'IL01')
	AND l.BALANCE > 0
	AND persflag.Cnt = 0
	AND acctflag.Cnt = 0
	AND DATEDIFF(d, GETDATE(), al.CURRDUEDATE) = 4
	AND l.ACCTNBR NOT IN
		(
			SELECT ACCTNBR
			FROM RW_DELINQUENT_MVIEW delq
			WHERE 
				delq.DL_LOAD_DATE = @DL_Load_Date
				AND delq.AMTDUE > 0
		)
	AND DATEDIFF(d, l.LAST_UNPAID_PMT_DATE, '2023-10-01') <= 3 -- hardcoded '2023-10-01' for testing
	AND l.SCHEDULED_PMT > 0

ORDER BY l.MEMBER_NBR, l.ACCTNBR
;











--WITH P AS (
--	SELECT
--		a.DL_LOAD_DATE
--		, a.MEMBERAGREENBR
--		, a.ACCTNBR
--		, a.TAXRPTFORPERSNBR
--		, b2.BALAMT
--		, Name = CONCAT(p.FIRSTNAME, ' ', p.MDLINIT, ' ', p.LASTNAME)
--		, pmt.PMTAMT
--		, a.MJACCTTYPCD
--		, a.CURRMIACCTTYPCD
--		, mi.MIACCTTYPDESC
--		, l.CURRDUEDATE
	
--	FROM 
--		ACCT a

--		INNER JOIN MJACCTTYP t
--			ON a.MJACCTTYPCD = t.MJACCTTYPCD

--		INNER JOIN MJMIACCTTYP mi
--			ON a.MJACCTTYPCD = mi.MJACCTTYPCD
--			AND a.CURRMIACCTTYPCD = mi.MIACCTTYPCD

--		INNER JOIN PERS p
--			ON a.DL_LOAD_DATE = p.DL_LOAD_DATE
--			AND a.TAXRPTFORPERSNBR = p.PERSNBR
		
--		INNER JOIN ACCTLOAN l
--			ON p.DL_LOAD_DATE = l.DL_LOAD_DATE
--			AND a.ACCTNBR = l.ACCTNBR

--		INNER JOIN
--			(SELECT 
--				b.DL_Load_Date
--				, b.ACCTNBR
--				, b.SUBACCTNBR
--				, Max_Eff_Date = MAX(b.EFFDATE)

--			FROM ACCTBALHIST b

--			GROUP BY b.DL_Load_Date, b.ACCTNBR, b.SUBACCTNBR
--			) b -- to get most recent EffDate in order to find recent loan balance
--			ON a.DL_LOAD_DATE = b.DL_LOAD_DATE
--			AND a.ACCTNBR = b.ACCTNBR
	
--		INNER JOIN ACCTBALHIST b2
--			ON b.DL_LOAD_DATE = b2.DL_LOAD_DATE
--			AND b.ACCTNBR = b2.ACCTNBR
--			AND b.SUBACCTNBR = b2.SUBACCTNBR
--			AND b.Max_Eff_Date = b2.EFFDATE
--			AND b2.SUBACCTNBR = 1

--		INNER JOIN ACCTPMTHIST pmt
--			ON a.DL_LOAD_DATE = pmt.DL_LOAD_DATE
--			AND a.ACCTNBR = pmt.ACCTNBR

--		CROSS APPLY (
--			SELECT Cnt = COUNT(*)
--			FROM PERSWRN pw
--			WHERE 
--				pw.WRNFLAGCD IN ('BSWF', 'COLL', 'REPO')
--				AND pw.DL_LOAD_DATE = @DL_Load_Date
--				AND a.TAXRPTFORPERSNBR = pw.PERSNBR
--		) persflag

--		CROSS APPLY (
--			SELECT Cnt = COUNT(*)
--			FROM ACCTWRN aw
--			WHERE 
--				aw.WRNFLAGCD IN ('NOTE')
--				AND aw.DL_LOAD_DATE = @DL_Load_Date
--				AND a.ACCTNBR = aw.ACCTNBR
--		) acctflag

--	WHERE
--		a.DL_LOAD_DATE = @DL_Load_Date
--		AND p.DATEDEATH IS NULL
--		AND t.MJACCTTYPCATCD = 'LOAN'
--		AND a.CURRACCTSTATCD = 'ACT'
--		AND a.MJACCTTYPCD = 'CNS'
--		AND a.CURRMIACCTTYPCD IN ('IN03', 'CS02', 'IN01', 'IN02', 'CS03', 'CS01', 'IL02', 'IL01')
--		AND DATEDIFF(d, GETDATE(), l.CURRDUEDATE) = 4
-----		and DATEDIFF(d,getdate(),l.next_due_date)= 4
--		AND b2.BALAMT > 0
--		AND pmt.PMTAMT > 0
--		AND persflag.Cnt = 0
--		AND acctflag.Cnt = 0
--		-- Delq condition
--)


--SELECT DISTINCT 
--	p.DL_LOAD_DATE
--	, Email = ''
--	, p.PMTAMT
--	, p.MEMBERAGREENBR
--	, p.ACCTNBR
--	, p.Name
--	, Cell1 = CONCAT('(', cp1.AREACD, ')', cp1.EXCHANGE, '-', cp1.PHONENBR)
--	, Cell2 = CONCAT('(', cp2.AREACD, ')', cp2.EXCHANGE, '-', cp2.PHONENBR)
--	, Cell3 = CONCAT('(', cp3.AREACD, ')', cp3.EXCHANGE, '-', cp3.PHONENBR)
--	, Phone = COALESCE(
--		right(cast('000' as char(3))+rtrim(cast(cp1.AREACD as char(3))),3)+
--		right (cast('000' as char(3))+rtrim(cast(cp1.EXCHANGE as char(3))),3)+
--		right (cast('0000' as char(4))+rtrim(cast(cp1.PHONENBR as char(4))),4),

--		right (cast('000' as char(3))+rtrim(cast(cp2.AREACD as char(3))),3)+
--		right (cast('000' as char(3))+rtrim(cast(cp2.EXCHANGE as char(3))),3)+
--		right (cast('0000' as char(4))+rtrim(cast(cp2.PHONENBR as char(4))),4),

--		right (cast('000' as char(3))+rtrim(cast(cp3.AREACD as char(3))),3)+
--		right (cast('000' as char(3))+rtrim(cast(cp3.EXCHANGE as char(3))),3)+
--		right (cast('0000' as char(4))+rtrim(cast(cp3.PHONENBR as char(4))),4))
--	, p.MJACCTTYPCD
--	, p.CURRMIACCTTYPCD
--	, p.MIACCTTYPDESC
--	, Next_Due_Date = p.CURRDUEDATE
--	, Home_Phone = COALESCE(
--		right(cast('000' as char(3))+rtrim(cast(hp1.AREACD as char(3))),3)+
--		right (cast('000' as char(3))+rtrim(cast(hp1.EXCHANGE as char(3))),3)+
--		right (cast('0000' as char(4))+rtrim(cast(hp1.PHONENBR as char(4))),4),

--		right (cast('000' as char(3))+rtrim(cast(hp2.AREACD as char(3))),3)+
--		right (cast('000' as char(3))+rtrim(cast(hp2.EXCHANGE as char(3))),3)+
--		right (cast('0000' as char(4))+rtrim(cast(hp2.PHONENBR as char(4))),4),

--		right (cast('000' as char(3))+rtrim(cast(hp3.AREACD as char(3))),3)+
--		right (cast('000' as char(3))+rtrim(cast(hp3.EXCHANGE as char(3))),3)+
--		right (cast('0000' as char(4))+rtrim(cast(hp3.PHONENBR as char(4))),4),

--		right (cast('000' as char(3))+rtrim(cast(hp5.AREACD as char(3))),3)+
--		right (cast('000' as char(3))+rtrim(cast(hp5.EXCHANGE as char(3))),3)+
--		right (cast('0000' as char(4))+rtrim(cast(hp5.PHONENBR as char(4))),4))

--FROM 
--	P

--	LEFT OUTER JOIN PERSPHONE cp1
--		ON p.DL_LOAD_DATE = cp1.DL_LOAD_DATE
--		AND p.TAXRPTFORPERSNBR = cp1.PERSNBR
--		AND cp1.PREFERREDYN = 'Y'
--		AND cp1.PHONEUSECD = 'CELL'
--		AND cp1.EXCHANGE <> 0
--		AND cp1.PHONENBR <> 0
--		AND cp1.CTRYCD = 'USA'

--	LEFT OUTER JOIN PERSPHONE cp2
--		ON p.DL_LOAD_DATE = cp2.DL_LOAD_DATE
--		AND p.TAXRPTFORPERSNBR = cp2.PERSNBR
--		AND cp2.PHONEUSECD = 'CELL'
--		-- Date_Made_Previous IS NULL ???
--		AND cp2.PHONESEQ = 1
--		AND cp2.EXCHANGE <> 0
--		AND cp2.PHONENBR <> 0
--		AND cp2.CTRYCD = 'USA'

--	LEFT JOIN
--		(
--		SELECT
--			Phone_Str = CONCAT('(', p.AREACD, ')', p.EXCHANGE, '-', p.PHONENBR)
--			, p.PERSNBR
--			, p.PHONELASTUPDATEDDATE
--			, p.DL_LOAD_DATE
--			, p.AREACD
--			, p.EXCHANGE
--			, p.PHONENBR
--			, row = ROW_NUMBER() OVER(PARTITION BY p.PERSNBR ORDER BY p.PHONELASTUPDATEDDATE DESC)

--		FROM 
--			PERSPHONE p

--		WHERE 
--			p.PHONEUSECD = 'CELL'
--			AND p.CTRYCD = 'USA'
--			AND p.DL_LOAD_DATE = @DL_Load_Date  -- included this condition for testing purpose
--		) AS cp3
--		ON p.DL_LOAD_DATE = cp3.DL_LOAD_DATE
--		AND p.TAXRPTFORPERSNBR = cp3.PERSNBR
--		AND cp3.row = 1

--	LEFT JOIN
--		(
--		SELECT
--			Phone_Str = CONCAT('(', p.AREACD, ')', p.EXCHANGE, '-', p.PHONENBR)
--			, p.PERSNBR
--			, p.PHONELASTUPDATEDDATE
--			, p.DL_LOAD_DATE
--			, p.AREACD
--			, p.EXCHANGE
--			, p.PHONENBR
--			, row = ROW_NUMBER() OVER(PARTITION BY p.PERSNBR ORDER BY p.PHONELASTUPDATEDDATE DESC)

--		FROM 
--			PERSPHONE p

--		WHERE 
--			p.PHONEUSECD = 'PER'
--			AND p.CTRYCD = 'USA'
--			AND p.DL_LOAD_DATE = @DL_Load_Date  -- included due to testing purpose
--		) AS hp5
--		ON p.TAXRPTFORPERSNBR = hp5.PERSNBR
--		AND p.DL_LOAD_DATE = hp5.DL_LOAD_DATE
--		AND hp5.row = 1
		
--	LEFT JOIN PERSPHONE hp1
--		ON p.DL_LOAD_DATE = hp1.DL_LOAD_DATE
--		AND p.TAXRPTFORPERSNBR = hp1.PERSNBR
--		AND hp1.PHONEUSECD = 'PER'
--		AND hp1.PREFERREDYN = 'Y'
--		AND hp1.EXCHANGE <> 0
--		AND hp1.PHONENBR <> 0
--		AND hp1.FOREIGNPHONENBR = 'USA'

--	LEFT JOIN PERSPHONE hp2
--		ON p.DL_LOAD_DATE = hp1.DL_LOAD_DATE
--		AND p.TAXRPTFORPERSNBR = hp1.PERSNBR
--		AND hp1.PHONEUSECD = 'PER'
--		---- Date_Made_Previous IS NULL ???
--		AND hp2.PHONESEQ = 1
--		AND hp2.EXCHANGE <> 0
--		AND hp2.PHONENBR <> 0
--		AND hp2.FOREIGNPHONENBR = 'USA'

--	LEFT JOIN PERSPHONE hp3
--		ON p.DL_LOAD_DATE = hp3.DL_LOAD_DATE
--		AND p.TAXRPTFORPERSNBR = hp3.PERSNBR
--		AND hp3.PHONEUSECD = 'PER'
--		AND hp3.PHONESEQ = 2
--		AND hp3.EXCHANGE <> 0
--		AND hp3.PHONENBR <> 0
--		AND hp3.FOREIGNPHONENBR = 'USA'

--ORDER BY p.MEMBERAGREENBR
--;
