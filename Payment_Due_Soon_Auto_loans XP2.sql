-- XP2

DECLARE @DL_Load_Date datetime = '2023-10-01';

IF @DL_Load_Date IS NULL
	SELECT @DL_Load_Date = DL_Load_Date
	FROM ID.MonthEnd_DL_Load_Dates
	WHERE sequence = 1;

select distinct
	l.dl_load_Date
	, '' as Email
	, l.scheduled_pmt
	, L.member_nbr
	, L.loan_nbr
	, ind.d1name as Name
	-- case when substring(ph.phone_str,1,1)='('
	-- Then
	-- substring(ph.phone_str,2,3)+'-'+substring(ph.phone_str,6,8)
	-- else ph.phone_str end as phone2,
	, Cphone1.phone_str as cell1
	, Cphone2.phone_str as cell2
	, Cphone3.phone_str as cell3
	-- COALESCE(Cphone1.phone_str,Cphone2.phone_str,Cphone3.phone_str) as cellphone,
	-- substring (COALESCE(Cphone1.phone_str,Cphone2.phone_str,Cphone3.phone_str),2,3)+
	-- substring (COALESCE(Cphone1.phone_str,Cphone2.phone_str,Cphone3.phone_str),6,3)+
	-- right(COALESCE(Cphone1.phone_str,Cphone2.phone_str,Cphone3.phone_str),4) as phone,
	, Phone = COALESCE(
		right(cast('000' as char(3))+rtrim(cast(Cphone1.area_code as char(3))),3)+
		right (cast('000' as char(3))+rtrim(cast(Cphone1.prefix as char(3))),3)+
		right (cast('0000' as char(4))+rtrim(cast(Cphone1.number as char(4))),4),
		right (cast('000' as char(3))+rtrim(cast(Cphone2.area_code as char(3))),3)+
		right (cast('000' as char(3))+rtrim(cast(Cphone2.prefix as char(3))),3)+
		right (cast('0000' as char(4))+rtrim(cast(Cphone2.number as char(4))),4),
		right (cast('000' as char(3))+rtrim(cast(Cphone3.area_code as char(3))),3)+
		right (cast('000' as char(3))+rtrim(cast(Cphone3.prefix as char(3))),3)+
		right (cast('0000' as char(4))+rtrim(cast(Cphone3.number as char(4))),4))
	, l.loan_type
	, b.ltincde
	, B.LTDESCP as type
	, l.next_due_date
	, HOME_PHONE = COALESCE(
		right(cast('000' as char(3))+rtrim(cast(HPhone.area_code as char(3))),3)+
		right (cast('000' as char(3))+rtrim(cast(HPhone.prefix as char(3))),3)+
		right (cast('0000' as char(4))+rtrim(cast(HPhone.number as char(4))),4),
		right (cast('000' as char(3))+rtrim(cast(Hphone2.area_code as char(3))),3)+
		right (cast('000' as char(3))+rtrim(cast(Hphone2.prefix as char(3))),3)+
		right (cast('0000' as char(4))+rtrim(cast(Hphone2.number as char(4))),4),
		right (cast('000' as char(3))+rtrim(cast(Hphone3.area_code as char(3))),3)+
		right (cast('000' as char(3))+rtrim(cast(Hphone3.prefix as char(3))),3)+
		right (cast('0000' as char(4))+rtrim(cast(Hphone3.number as char(4))),4),
		right (cast('000' as char(3))+rtrim(cast(Hphone5.area_code as char(3))),3)+
		right (cast('000' as char(3))+rtrim(cast(Hphone5.prefix as char(3))),3)+
		right (cast('0000' as char(4))+rtrim(cast(Hphone5.number as char(4))),4))


From 
	LOAN  L
  
	inner join membership mem
		on l.dl_load_date = mem.dl_load_date
		and l.member_nbr =mem.member_nbr

	inner join membershipparticipant mp
		on l.dl_load_date= mp.dl_load_date
        and l.member_nbr = mp.member_nbr
        and mp.participation_type = 101

	join dbo.INDIVIDUAL ind
		on  mp.INDIVIDUAL_ID = ind.INDIVIDUAL_ID
		and mp.DL_LOAD_DATE = ind.DL_LOAD_DATE

	inner join Base_Ltrcd B
		on L.LOAN_type = B. LTTYPE_

	left outer join phone Cphone1
		on ind.individual_id = CPHONE1.individual_id
		and ind.DL_LOAD_DATE = Cphone1.DL_LOAD_DATE
		and CPHONE1.is_primary_for_type = 1
		and CPHONE1.phone_type = 'C'
		and CPHONE1.prefix <>0
		and CPHONE1.number <>0
		and Cphone1.is_intl_nbr<>1

	left join phone Cphone2
		on Cphone2.individual_id =ind.individual_id
		and ind.DL_LOAD_DATE = Cphone2.DL_LOAD_DATE
		and Cphone2.phone_type = 'C'
		AND  Cphone2.DATE_MADE_PREVIOUS IS  NULL
		AND Cphone2.SEQ=1
		and cphone2.prefix <>0
		and Cphone2.number <>0
		and Cphone2.is_intl_nbr<>1

	left join
		(select 
			p.phone_str
			, p.INDIVIDUAL_ID
			, p.xptimestamp
			, p.dl_load_date
			, p.area_code
			, p.prefix
			, p.number
			, row_number() OVER(PARTITION BY p.individual_id order by p.xptimestamp desc) AS row

		from phone p -- Originally was using phone_today
        
		where  
			p.phone_type ='C'
            and p.is_intl_nbr<>1
			and p.DL_LOAD_DATE = @DL_Load_Date  -- for testing purpose. originally doesn't have this condition
		) as Cphone3
		on ind.individual_id =Cphone3.individual_id
		and ind.dl_load_date =Cphone3.dl_load_date
		and Cphone3.row =1

	left join
		(select 
			pp.phone_str 
			, pp.INDIVIDUAL_ID
			, pp.xptimestamp
			, pp.dl_load_date
			, pp.area_code
			, pp.prefix
			, pp.number
			, row_number() OVER(PARTITION BY  pp.individual_id order by pp.xptimestamp desc) AS row
			
		from phone pp -- phone_today pp -- changed due to testing purpose
		
		where  
			pp.phone_type ='H'
			and pp.is_intl_nbr<>1
			and pp.DL_LOAD_DATE = @DL_Load_Date -- for testing purpose
		)as HPhone5
		on ind.individual_id =HPhone5.individual_id
		and ind.dl_load_date =HPhone5.dl_load_date
		and HPhone5.row =1

	left join phone HPhone
		on HPhone.individual_id =ind.individual_id
		and ind.DL_LOAD_DATE = HPhone.DL_LOAD_DATE
		and HPhone.phone_type ='H'
		and HPhone.Is_primary_for_type=1
		and HPhone.prefix <>0
		and HPhone.number <>0
		and HPhone.is_intl_nbr<>1

	left join phone HPhone2
		on Hphone2.individual_id =ind.individual_id
		and ind.DL_LOAD_DATE = HPhone2.DL_LOAD_DATE
		and Hphone2.phone_type ='H'
		AND  HPHONE2.DATE_MADE_PREVIOUS IS  NULL
		AND Hphone2.SEQ=1
		and Hphone2.prefix <>0
		and Hphone2.number <>0
		and HPhone2.is_intl_nbr<>1

	left join phone HPhone3
		on Hphone3.individual_id =ind.individual_id
		and ind.DL_LOAD_DATE = HPhone3.DL_LOAD_DATE
		and Hphone3.phone_type ='H'
		AND  HPHONE3.DATE_MADE_PREVIOUS IS  NULL
		AND Hphone3.SEQ=2
		and Hphone3.prefix <>0
		and Hphone3.number <>0
		and HPhone3.is_intl_nbr<>1

where  
	l.DL_LOAD_DATE = @DL_Load_Date
	and mp.participation_type = 101
	and ind.death_date is  null
	AND  L.branch_nbr <> 63
	and ((is_written_off is null) or (is_written_off = 0))
	and ((closed is null) or (closed = 0))
	and l.loan_type in (1,9,11,14,15,16,34,35,36,37,39,41,82,89,90,91,92,140,141)
	and not exists ( select * from membershipwarning mw -- COLLECTION , BANKRUPTCY CODES
					 where  mw.WARNING_CODE in  (4,5,6,8,9,10,18)
					 and mem.member_nbr =mw.member_nbr
					 and mem.dl_load_date=mw.dl_load_date )
	and ind.d1name not like'%TRUST%'
	and l.balance >0
	and DATEDIFF(d,getdate(),l.next_due_date)=4
	and not exists ( select * from   AGR_LOANDELQ  agr_del
					 where l.member_nbr =agr_del.member_nbr
					 and l.loan_nbr=agr_del.loan_nbr
				   and l.DL_LOAD_DATE = agr_del.DL_LOAD_DATE
				   and agr_del.delamt>0
				   and agr_del.daysdel>3)
	and l.scheduled_pmt>0

order by l.member_nbr,l.loan_nbr
;