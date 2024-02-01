-- LNFER Extracts - Payment_Due_Soon_Personal_loans
		  --------------------------------------------------------------------------------------------------------------------------
		  --------------------------------------------------------------------------------------------------------------------------
-- DNA



DECLARE @DL_Load_Date datetime = '2023-10-02';

IF @DL_Load_Date IS NULL
	SELECT @DL_Load_Date = DL_Load_Date
	FROM ID.MonthEnd_DL_Load_Dates
	WHERE sequence = 1;

WITH A AS
(
	
	SELECT  A.ACCTNBR
			, A.DL_LOAD_DATE
			, Email = ''			
			, member_nbr = A.MEMBERAGREENBR
			, loan_nbr = A.ACCTNBR
			, Name = CONCAT(P.FIRSTNAME, ' ', P.MDLNAME, ' ', P.LASTNAME)		
			, loan_type = A.MJACCTTYPCD
			, ltincde = A.CURRMIACCTTYPCD
			, type = mi.MIACCTTYPDESC 
			--, type = A.ACCTDESC -- Was showing NULL due to it being NULL in the Acct Table
			, next_due_date = AL.CURRDUEDATE
			, HOME_PHONE = ''
			, P.PERSNBR
	FROM ACCT A
	
	INNER JOIN ACCTLOAN AL
		ON A.DL_LOAD_DATE = AL.DL_LOAD_DATE
		AND A.ACCTNBR = AL.ACCTNBR
		
	INNER JOIN PERS P
			ON P.DL_LOAD_DATE = A.DL_LOAD_DATE
			AND P.PERSNBR = A.TAXRPTFORPERSNBR

	INNER JOIN MJMIACCTTYP mi -- Added just to get the Loce Type Desc for the Type column
			ON a.MJACCTTYPCD = mi.MJACCTTYPCD
			AND a.CURRMIACCTTYPCD = mi.MIACCTTYPCD

	WHERE A.DL_LOAD_DATE= @DL_Load_Date
	AND a.MJACCTTYPCD = 'CNS'
	AND a.CURRMIACCTTYPCD IN ('IN04', 'CU01')
	AND a.CURRACCTSTATCD = 'ACT'
	AND a.BANKORGNBR <> 63
	AND P.DATEDEATH IS NULL
	AND DATEDIFF(d, GETDATE(), AL.CURRDUEDATE) = 4
)


SELECT A.DL_LOAD_DATE
		, Email = ''
		, scheduled_pmt = cast(PMT.PMTAMT as decimal(18,2))
		, member_nbr
		, loan_nbr
		, Name 
		, cell1 = CellPhone.[1]
		, cell2 = CellPhone.[2]
		, cell3 = CellPhone.[3]
		, Phone = CellPhone.[1]
		, loan_type 
		, ltincde
		, type
		, next_due_date
		, HOME_PHONE= HomePhone.[1] -- Will only the Seq 1 PER phone as of right now
FROM A

CROSS APPLY 
(
	SELECT Cnt = COUNT(*)
	FROM PERSWRN pw
	WHERE pw.WRNFLAGCD IN ('BSWF', 'COLL', 'REPO')
		  AND pw.DL_LOAD_DATE = @DL_Load_Date
		  AND a.PERSNBR = pw.PERSNBR
) persflag

CROSS APPLY 
(
	SELECT Cnt = COUNT(*)
	FROM ACCTWRN aw
	WHERE 
		aw.WRNFLAGCD IN ('NOTE')
		AND aw.DL_LOAD_DATE = @DL_Load_Date
		AND a.ACCTNBR = aw.ACCTNBR
) acctflag

CROSS APPLY
(
		SELECT [1] = MAX([1])
			, [2] = MAX([2])
			, [3] = MAX([3])
		FROM
		(
			SELECT ph.PERSNBR
				, Phone_Str = CONCAT('(', ph.AREACD, ') ', ph.EXCHANGE, '-', ph.PHONENBR)
				, row = ROW_NUMBER() OVER(ORDER BY ph.PhoneSeq ASC, ph.PHONELASTUPDATEDDATE DESC)
			FROM 
			PERSPHONE ph
			WHERE ph.PHONEUSECD = 'CELL'
				  AND ph.CTRYCD = 'USA'
				  AND ph.DL_LOAD_DATE = A.DL_Load_Date
				  AND Ph.PERSNBR = A.PERSNBR
		) P
		PIVOT
		(
			MAX(Phone_Str)
			FOR row IN ([1],[2],[3])
		) T
) CellPhone

CROSS APPLY
(
	SELECT PMTAMT = MAX(PMTAMT)
	FROM
	(
		SELECT PMTAMT,
			RN = ROW_NUMBER() OVER (ORDER BY EFFDATE DESC)
		FROM ACCTPMTHIST
		WHERE ACCTNBR = A.ACCTNBR
			AND PMTTYPCD = 'FDUE'
	) T
	WHERE RN = 1
) PMT

--Mike Stegall
CROSS APPLY -- Just to get the a pers Phone for Home_Phone
(
		SELECT [1] = MAX([1])
			--, [2] = MAX([2])
			--, [3] = MAX([3])
		FROM
		(
			SELECT ph.PERSNBR
				, Phone_Str = CONCAT('(', ph.AREACD, ') ', ph.EXCHANGE, '-', ph.PHONENBR)
				, row = ROW_NUMBER() OVER(ORDER BY ph.PhoneSeq ASC, ph.PHONELASTUPDATEDDATE DESC)
			FROM 
			PERSPHONE ph
			WHERE ph.PHONEUSECD = 'Per'
				  AND ph.CTRYCD = 'USA'
				  AND ph.DL_LOAD_DATE = A.DL_Load_Date
				  AND Ph.PERSNBR = A.PERSNBR
		) P
		PIVOT
		(
			MAX(Phone_Str)
			FOR row IN ([1])--,[2],[3])
		) T
)HomePhone

WHERE persflag.Cnt = 0
	AND acctflag.Cnt = 0


ORDER BY A.member_nbr, A.ACCTNBR;

--Select MEMBERAGREEMENT
--      ,MIACCTTYPDESC 
--      ,CURRMIACCTTYPCD
--	  ,MJACCTTYPCD       
--from ACCTLOAN 
--WHERE AND a.MJACCTTYPCD = 'CNS'
--	  AND a.CURRMIACCTTYPCD IN ('IN03', 'CS02', 'IN01', 'IN02', 'CS03', 'CS01', 'IL02', 'IL01')
	   