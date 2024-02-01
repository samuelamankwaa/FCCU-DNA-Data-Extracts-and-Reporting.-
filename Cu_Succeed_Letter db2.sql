select 
	s.MEMBER_NBR
	, s.SHARE_NBR
	, s.SHARE_TYPE
	, dt.DTINCODE
	, s.BALANCE
	, CURRENT DATE as Current_Date
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

from 
	DB2INST1.SHARE s

	join DB2INST1.BASE_DTRCD dt
		on dt.DT_ = s.SHARE_TYPE

	join DB2INST1.MEMBERSHIP m
		on m.MEMBER_NBR = s.MEMBER_NBR

	join DB2INST1.MEMBERSHIPADDRESS ma
		on ma.MEMBER_NBR = m.MEMBER_NBR
		and ma.MEMBERSHIP_ADDRESS_TYPE = 1

	join DB2INST1.ADDRESS a
		on a.ADDRESS_ID = ma.ADDRESS_ID

	join DB2INST1.MEMBERSHIPPARTICIPANT mp
		on mp.MEMBER_NBR = m.MEMBER_NBR
		and mp.PARTICIPATION_TYPE = 101

	join DB2INST1.INDIVIDUAL i
		on i.INDIVIDUAL_ID = mp.INDIVIDUAL_ID

	join 
		(
			select m.MEMBER_NBR
			from DB2INST1.MEMBERSHIP m
			where
				m.BRANCH <> 63
				and (m.PURGE IS NULL or m.PURGE = 0)
				and m.MEMBER_NBR NOT IN 
					(
						select distinct mw.MEMBER_NBR
						from DB2INST1.MEMBERSHIPWARNING mw
						where 
							mw.WARNING_CODE in (1,4,5,8,9)
							and (mw.WARNING_EXPIRATION_DATE IS NULL or mw.WARNING_EXPIRATION_DATE > CURRENT DATE)
							and mw.WARNING_TYPE = 1
						order by mw.MEMBER_NBR
					)
			order by m.MEMBER_NBR
		) as mailcheck 
		on s.member_nbr = mailcheck.member_nbr

where  
	s.MEMBER_BRANCH <> 63
	and (s.WOFF is NULL or s.WOFF = 0)
	and (s.CLOSED is NULL or s.CLOSED = 0)
	and s.SHARE_TYPE in (1,3,9,10)
	and i.death_date is null
	and i.BIRTH_DATE 
		between Date(CAST(YEAR((CURRENT DATE - 18 YEARS) - 1 MONTH) as varchar(4)) ||'-'|| CAST(MONTH((CURRENT DATE - 18 YEARS) - 1 MONTH) as varchar(2)) ||'-16')
        and Date(CAST(YEAR((CURRENT DATE - 18 YEARS)) as varchar(4)) ||'-'|| CAST(MONTH((CURRENT DATE - 18 YEARS)) as varchar(2)) ||'-15') 
		--Gets birthday from last month on 16th through the 15th
	and s.member_nbr NOT IN
        (
			Select ai.member_nbr
			from db2inst1.membershipparticipant ai
			where ai.participation_type in (124,126)
			order by ai.member_nbr
        )