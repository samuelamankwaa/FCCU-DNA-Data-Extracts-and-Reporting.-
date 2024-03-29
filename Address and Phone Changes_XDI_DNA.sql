SELECT
   CASE
       WHEN sub.DATABASEACTVCD = 'ADD' THEN 'Adding Address'
       WHEN sub.DATABASEACTVCD = 'UPD' THEN 'Updating Address'
       WHEN sub.DATABASEACTVCD = 'DEL' THEN 'Deleting Address'
   END AS UPDATE_TYPE,
   p.PERSNBR,
   p.FIRSTNAME,
   p.LASTNAME,
   MAX(CASE WHEN sub.COLUMNID = 'AddrLineText' THEN sub.OLDVALUE ELSE NULL END)
   + ', ' +
   MAX(CASE WHEN sub.COLUMNID = 'CITYNAME' THEN sub.OLDVALUE ELSE NULL END)
   + ', ' +
   MAX(CASE WHEN sub.COLUMNID = 'STATECD' THEN sub.OLDVALUE ELSE NULL END)
   + ' ' +
   MAX(CASE WHEN sub.COLUMNID = 'ZIPCD' THEN sub.OLDVALUE ELSE NULL END) AS 'OLD_VALUE',
   MAX(CASE WHEN sub.COLUMNID = 'AddrLineText' THEN sub.NEWVALUE ELSE NULL END)
   + ', ' +
   MAX(CASE WHEN sub.COLUMNID = 'CITYNAME' THEN sub.NEWVALUE ELSE NULL END)
   + ', ' +
   MAX(CASE WHEN sub.COLUMNID = 'STATECD' THEN sub.NEWVALUE ELSE NULL END)
   + ' ' +
   MAX(CASE WHEN sub.COLUMNID = 'ZIPCD' THEN sub.NEWVALUE ELSE NULL END) AS 'NEW_VALUE'
FROM dbo.PERS p
INNER JOIN dbo.ACTV a ON p.PERSNBR = a.SUBJPERSNBR AND p.DL_LOAD_DATE = a.DL_LOAD_DATE
INNER JOIN dbo.ACTVSUBACTV sub ON sub.ACTVNBR = a.ACTVNBR AND sub.DL_LOAD_DATE = a.DL_LOAD_DATE
INNER JOIN dbo.ACTVSUBACTV sub2 ON sub2.ACTVNBR = a.ACTVNBR AND sub2.DL_LOAD_DATE = a.DL_LOAD_DATE AND sub2.COLUMNID = 'AddrLineType' AND sub2.NEWVALUE = 'ST'
WHERE a.DL_LOAD_DATE = '2023-10-02'
AND a.ACTVCATCD = 'PMNT'
AND a.ACTVTYPCD = 'PERS'
AND sub.DATABASEACTVCD IN ('ADD', 'UPD', 'DEL')
AND sub.TABLEID in ('ADDR', 'ADDRLINE')
GROUP BY sub.DATABASEACTVCD, p.PERSNBR, p.FIRSTNAME, p.LASTNAME, a.ACTVCATCD, a.ACTVTYPCD
UNION ALL
SELECT
   CASE
       WHEN sub.DATABASEACTVCD = 'ADD' THEN 'Adding Phone Number'
       WHEN sub.DATABASEACTVCD = 'UPD' THEN 'Updating Phone Number'
       WHEN sub.DATABASEACTVCD = 'DEL' THEN 'Deleting Phone Number'
   END AS UPDATE_TYPE,
   p.PERSNBR,
   p.FIRSTNAME,
   p.LASTNAME,
   MAX(CASE WHEN sub.COLUMNID = 'AREACD' THEN sub.OLDVALUE ELSE NULL END)
   + '-' +
   MAX(CASE WHEN sub.COLUMNID = 'EXCHANGE' THEN sub.OLDVALUE ELSE NULL END)
   + '-' +
   MAX(CASE WHEN sub.COLUMNID = 'PHONENBR' THEN sub.OLDVALUE ELSE NULL END) AS 'OLD_VALUE',
   MAX(CASE WHEN sub.COLUMNID = 'AREACD' THEN sub.NEWVALUE ELSE NULL END)
   + '-' +
   MAX(CASE WHEN sub.COLUMNID = 'EXCHANGE' THEN sub.NEWVALUE ELSE NULL END)
   + '-' +
   MAX(CASE WHEN sub.COLUMNID = 'PHONENBR' THEN sub.NEWVALUE ELSE NULL END) AS 'NEW_VALUE'
FROM dbo.PERS p
INNER JOIN dbo.ACTV a ON p.PERSNBR = a.SUBJPERSNBR AND p.DL_LOAD_DATE = a.DL_LOAD_DATE
INNER JOIN dbo.ACTVSUBACTV sub ON sub.ACTVNBR = a.ACTVNBR AND sub.DL_LOAD_DATE = a.DL_LOAD_DATE
WHERE a.DL_LOAD_DATE = '2023-10-02'
AND a.ACTVCATCD = 'PMNT'
AND a.ACTVTYPCD = 'PERS'
AND sub.DATABASEACTVCD IN ('ADD', 'UPD', 'DEL')
AND sub.TABLEID = 'PERSPHONE'
GROUP BY sub.DATABASEACTVCD, p.PERSNBR, p.FIRSTNAME, p.LASTNAME, a.ACTVCATCD, a.ACTVTYPCD