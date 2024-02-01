-- XP2, converted from db2 first

-- DECLARE @DL_Load_Date datetime = '2024-01-14'; -- testing: converting from db2 to xp2
DECLARE @DL_Load_Date datetime = '2023-10-01'; -- testing: DNA query

IF @DL_Load_Date IS NULL
	SELECT @DL_Load_Date = DL_Load_Date
	FROM ID.MonthEnd_DL_Load_Dates
	WHERE sequence = 1;


select 
	s.MEMBER_NBR
	, s.SHARE_NBR
	, s.SHARE_TYPE
	, dt.DTINCODE
	, s.BALANCE
	, 'Current_Date' = @DL_Load_Date
	, i.BIRTH_DATE
	, i.GENDER
	, i.NAME_PREFIX
	, i.D1NAME
	, i.FIRST_NAME
	, i.MIDDLE_NAME
	, i.LAST_NAME
	, a.ADDRESS1
	, a.ADDRESS2
	, a.CITY
	, a.STATE
	, a.ZIP_STR
	, a.ZIP4_STR
	--, i.INDIVIDUAL_TYPE -- testing

from 
	SHARE s

	join BASE_DTRCD dt
		on dt.DT_ = s.SHARE_TYPE

	join MEMBERSHIP m
		on m.MEMBER_NBR = s.MEMBER_NBR
		AND s.DL_LOAD_DATE = m.DL_LOAD_DATE

	join MEMBERSHIPADDRESS ma
		on ma.MEMBER_NBR = m.MEMBER_NBR
		and ma.MEMBERSHIP_ADDRESS_TYPE = 1
		AND ma.DL_LOAD_DATE = m.DL_LOAD_DATE

	join ADDRESS a
		on a.ADDRESS_ID = ma.ADDRESS_ID
		AND a.DL_LOAD_DATE = ma.DL_LOAD_DATE

	join MEMBERSHIPPARTICIPANT mp
		on mp.MEMBER_NBR = m.MEMBER_NBR
		and mp.PARTICIPATION_TYPE = 101
		AND mp.DL_LOAD_DATE = m.DL_LOAD_DATE

	join INDIVIDUAL i
		on i.INDIVIDUAL_ID = mp.INDIVIDUAL_ID
		AND i.DL_LOAD_DATE = mp.DL_LOAD_DATE

	join 
		(
			select 
				m.MEMBER_NBR
			from 
				MEMBERSHIP m
			where
				m.BRANCH <> 63
				and (m.PURGE IS NULL or m.PURGE = 0)
				and m.MEMBER_NBR NOT IN 
					(
						select distinct 
							mw.MEMBER_NBR
						from 
							MEMBERSHIPWARNING mw
						where 
							mw.WARNING_CODE in (1,4,5,8,9)
							and (mw.WARNING_EXPIRATION_DATE IS NULL or mw.WARNING_EXPIRATION_DATE > @DL_Load_Date)
							and mw.WARNING_TYPE = 1
							and mw.DL_LOAD_DATE = @DL_Load_Date
						--order by mw.MEMBER_NBR
					)
				AND m.DL_LOAD_DATE = @DL_Load_Date
			--order by m.MEMBER_NBR
		) as mailcheck 
		on s.member_nbr = mailcheck.member_nbr

where  
	s.DL_LOAD_DATE = @DL_Load_Date
	AND s.MEMBER_BRANCH <> 63
	and (s.WOFF is NULL or s.WOFF = 0)
	and (s.CLOSED is NULL or s.CLOSED = 0)
	and s.SHARE_TYPE in (1,3,9,10)
	and i.death_date is null
	and i.BIRTH_DATE 
		between -- Date(CAST(YEAR((CURRENT DATE - 18 YEARS) - 1 MONTH) as varchar(4)) ||'-'|| CAST(MONTH((CURRENT DATE - 18 YEARS) - 1 MONTH) as varchar(2)) ||'-16')
			CAST(CONCAT(
				CAST(YEAR(DATEADD(month, -1, DATEADD(year, -18, GETDATE()))) AS VARCHAR(4)),
				'-', 
				CAST(MONTH(DATEADD(month, -1, DATEADD(year, -18, GETDATE()))) AS VARCHAR(2)), 
				'-16') AS DATE)
        and --Date(CAST(YEAR((CURRENT DATE - 18 YEARS)) as varchar(4)) ||'-'|| CAST(MONTH((CURRENT DATE - 18 YEARS)) as varchar(2)) ||'-15')
			CAST(CONCAT(
				CAST(YEAR(DATEADD(year, -18, GETDATE())) AS VARCHAR(4)),
				'-',
				CAST(MONTH(DATEADD(year, -18, GETDATE())) AS VARCHAR(2)),
				'-15') AS DATE)
		--Gets birthday from last month on 16th through the 15th
	and s.member_nbr NOT IN
        (
			Select 
				ai.member_nbr
			from 
				membershipparticipant ai
			where 
				ai.participation_type in (124,126)
				AND ai.DL_LOAD_DATE = @DL_Load_Date
			--order by ai.member_nbr
        )

ORDER BY s.MEMBER_NBR -- testing
;