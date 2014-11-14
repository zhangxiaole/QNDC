SET NAMES 'utf8';
--$$

CREATE PROCEDURE `runweekly`(IN `begindate` DATE, IN `enddate` DATE)
    NO SQL
begin

DECLARE s datetime; 
DECLARE e datetime; 
DECLARE col VARCHAR(16); 
DECLARE days INT; 
DECLARE w INT; 

insert into razor_log(op_type,op_name,op_starttime) 
    values('runweekly','-----start runweekly-----',now());
    
set s = now();

-- generate the count of new users for last week

-- for channels, versions
INSERT INTO razor_sum_reserveusers_weekly 
            (startdate_sk, 
             enddate_sk, 
             product_id, 
             version_name, 
             channel_name, 
             usercount) 
SELECT (SELECT date_sk 
        FROM   razor_dim_date 
        WHERE  datevalue = begindate)     startdate_sk, 
       (SELECT date_sk 
        FROM   razor_dim_date 
        WHERE  datevalue = enddate)       enddate_sk, 
       ifnull(p.product_id,-1), 
       ifnull(p.version_name,'all'),
       ifnull(p.channel_name,'all'), 
       Count(DISTINCT f.deviceidentifier) count 
FROM   razor_fact_clientdata f, 
       razor_dim_date d, 
       razor_dim_product p 
WHERE  f.date_sk = d.date_sk 
       AND d.datevalue BETWEEN begindate AND enddate 
       AND f.product_sk = p.product_sk 
       AND p.product_active = 1 
       AND p.channel_active = 1 
       AND p.version_active = 1 
       AND f.isnew = 1 
GROUP  BY p.product_id, 
          p.version_name,
          p.channel_name with rollup
union
SELECT (SELECT date_sk 
        FROM   razor_dim_date 
        WHERE  datevalue = begindate)     startdate_sk, 
       (SELECT date_sk 
        FROM   razor_dim_date 
        WHERE  datevalue = enddate)       enddate_sk, 
       ifnull(p.product_id,-1), 
       ifnull(p.version_name,'all'),
       ifnull(p.channel_name,'all'), 
       Count(DISTINCT f.deviceidentifier) count 
FROM   razor_fact_clientdata f, 
       razor_dim_date d, 
       razor_dim_product p 
WHERE  f.date_sk = d.date_sk 
       AND d.datevalue BETWEEN begindate AND enddate 
       AND f.product_sk = p.product_sk 
       AND p.product_active = 1 
       AND p.channel_active = 1 
       AND p.version_active = 1 
       AND f.isnew = 1 
GROUP  BY p.product_id, 
          p.channel_name,
          p.version_name with rollup
ON DUPLICATE KEY UPDATE usercount=VALUES(usercount);


set e = now();
insert into razor_log(op_type,op_name,op_starttime,op_date,affected_rows,duration) 
    values('runweekly','razor_sum_reserveusers_weekly new users for app,version,channel dimensions',s,e,row_count(),TIMESTAMPDIFF(SECOND,s,e));


set w = 1;
while w<=8 do
  begin
    set col = concat('week',w);

    set days = -w*7;
    
    set s = now();
    
    -- 8 weeks for app,channel, version
    SET @sql=concat(
        'insert into razor_sum_reserveusers_weekly(startdate_sk, enddate_sk, product_id, version_name,channel_name,',
        col,
        ')
        Select 
        (select date_sk from razor_dim_date where datevalue= date_add(\'',begindate,'\',interval ',days,' DAY)) startdate,
        (select date_sk from razor_dim_date where datevalue= date_add(\'',enddate,'\',interval ',days,' DAY)) enddate,
        ifnull(p.product_id,-1),ifnull(p.version_name,\'all\'),ifnull(p.channel_name,\'all\'),
        count(distinct f.deviceidentifier)
        from
        razor_fact_clientdata f, razor_dim_date d, razor_dim_product p where f.date_sk = d.date_sk 
        and f.product_sk = p.product_sk and d.datevalue between \'',begindate,'\' and \'',enddate,'\' and p.product_active=1 
        and p.channel_active=1 and p.version_active=1 and exists 
         (select 1 from razor_fact_clientdata ff, razor_dim_product pp, razor_dim_date dd where ff.product_sk = pp.product_sk 
         and ff.date_sk = dd.date_sk and pp.product_id = p.product_id and dd.datevalue between 
         date_add(\'',begindate,'\',interval ',days,' DAY) and 
         date_add(\'',enddate,'\',interval ',days,' DAY) and ff.deviceidentifier = f.deviceidentifier and pp.product_active=1 
         and pp.channel_active=1 and pp.version_active=1 and ff.isnew=1) group by p.product_id,p.version_name,p.channel_name with rollup
         union
         Select 
        (select date_sk from razor_dim_date where datevalue= date_add(\'',begindate,'\',interval ',days,' DAY)) startdate,
        (select date_sk from razor_dim_date where datevalue= date_add(\'',enddate,'\',interval ',days,' DAY)) enddate,
        ifnull(p.product_id,-1),ifnull(p.version_name,\'all\'),ifnull(p.channel_name,\'all\'),
        count(distinct f.deviceidentifier)
        from
        razor_fact_clientdata f, razor_dim_date d, razor_dim_product p where f.date_sk = d.date_sk 
        and f.product_sk = p.product_sk and d.datevalue between \'',begindate,'\' and \'',enddate,'\' and p.product_active=1 
        and p.channel_active=1 and p.version_active=1 and exists 
         (select 1 from razor_fact_clientdata ff, razor_dim_product pp, razor_dim_date dd where ff.product_sk = pp.product_sk 
         and ff.date_sk = dd.date_sk and pp.product_id = p.product_id and dd.datevalue between 
         date_add(\'',begindate,'\',interval ',days,' DAY) and 
         date_add(\'',enddate,'\',interval ',days,' DAY) and ff.deviceidentifier = f.deviceidentifier and pp.product_active=1 
         and pp.channel_active=1 and pp.version_active=1 and ff.isnew=1) group by p.product_id,p.channel_name,p.version_name with rollup
        on duplicate key update ',col,'=values(',col,');');
        
    
    PREPARE sl FROM @sql;
    EXECUTE sl;
    DEALLOCATE PREPARE sl;
    
    set e = now();
    insert into razor_log(op_type,op_name,op_starttime,op_date,affected_rows,duration) 
    values('runweekly',concat('razor_sum_reserveusers_weekly WEEK ',-w,' reserve users for app,channel,version dimensions'),s,e,row_count(),TIMESTAMPDIFF(SECOND,s,e));
    
    set w = w + 1; 
  end;
end while;

set s = now();
INSERT INTO razor_sum_basic_activeusers 
            (product_id, 
             week_activeuser, 
             week_percent) 
SELECT p.product_id, 
       Count(DISTINCT f.deviceidentifier) activeusers, 
       Count(DISTINCT f.deviceidentifier) / (SELECT 
       Count(DISTINCT ff.deviceidentifier) 
                                             FROM   razor_fact_clientdata ff, 
                                                    razor_dim_date dd, 
                                                    razor_dim_product pp 
                                             WHERE  dd.datevalue <= enddate 
                                                    AND 
                                            p.product_id = pp.product_id 
                                                    AND pp.product_active = 1 
                                                    AND pp.channel_active = 1 
                                                    AND pp.version_active = 1 
                                                    AND 
                                            ff.product_sk = pp.product_sk 
                                                    AND ff.date_sk = dd.date_sk) 
                                          percent 
FROM   razor_fact_clientdata f, 
       razor_dim_date d, 
       razor_dim_product p 
WHERE  d.datevalue BETWEEN begindate AND enddate 
       AND p.product_active = 1 
       AND p.channel_active = 1 
       AND p.version_active = 1 
       AND f.product_sk = p.product_sk 
       AND f.date_sk = d.date_sk 
GROUP  BY p.product_id 
ON DUPLICATE KEY UPDATE week_activeuser = VALUES(week_activeuser),week_percent = VALUES(week_percent);

set e = now();
insert into razor_log(op_type,op_name,op_starttime,op_date,affected_rows,duration) 
    values('runweekly','razor_sum_basic_activeusers week activeuser and percent',s,e,row_count(),TIMESTAMPDIFF(SECOND,s,e));
    
set s = now();
INSERT INTO razor_sum_basic_channel_activeusers 
            (date_sk, 
             product_id, 
             channel_id, 
             activeuser, 
             percent, 
             flag) 
SELECT (SELECT date_sk 
        FROM   razor_dim_date 
        WHERE  datevalue = begindate)     startdate, 
       p.product_id, 
       p.channel_id, 
       Count(DISTINCT f.deviceidentifier) activeusers, 
       Count(DISTINCT f.deviceidentifier) / (SELECT 
       Count(DISTINCT ff.deviceidentifier) 
                                             FROM   razor_fact_clientdata ff, 
                                                    razor_dim_date dd, 
                                                    razor_dim_product pp 
                                             WHERE  dd.datevalue <= enddate 
                                                    AND 
                                            pp.product_id = p.product_id 
                                                    AND 
                                            pp.channel_id = p.channel_id 
                                                    AND pp.product_active = 1 
                                                    AND pp.channel_active = 1 
                                                    AND pp.version_active = 1 
                                                    AND 
                                            ff.product_sk = pp.product_sk 
                                                    AND ff.date_sk = dd.date_sk) 
       , 
       0 
FROM   razor_fact_clientdata f, 
       razor_dim_date d, 
       razor_dim_product p 
WHERE  d.datevalue BETWEEN begindate AND enddate 
       AND p.product_active = 1 
       AND p.channel_active = 1 
       AND p.version_active = 1 
       AND f.product_sk = p.product_sk 
       AND f.date_sk = d.date_sk 
GROUP  BY p.product_id, 
          p.channel_id 
ON DUPLICATE KEY UPDATE activeuser = VALUES(activeuser),percent=VALUES(percent);

set e = now();
insert into razor_log(op_type,op_name,op_starttime,op_date,affected_rows,duration) 
    values('runweekly','razor_sum_basic_channel_activeusers each channel active user and percent',s,e,row_count(),TIMESTAMPDIFF(SECOND,s,e));

insert into razor_log(op_type,op_name,op_starttime) 
    values('runweekly','-----finish runweekly-----',now());
    

end;