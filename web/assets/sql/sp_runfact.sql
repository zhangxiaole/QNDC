SET NAMES 'utf8';
--$$

CREATE PROCEDURE `runfact`(IN `starttime` DATETIME, IN `endtime` DATETIME)
    NO SQL
begin
declare s datetime;
declare e datetime;

insert into razor_log(op_type,op_name,op_starttime)
    values('runfact','-----start  runfact-----',now());

set s = now();

insert into razor_fact_clientdata
           (product_sk,
            deviceos_sk,
            deviceresolution_sk,
            devicelanguage_sk,
            devicebrand_sk,
            devicesupplier_sk,
            location_sk,
            date_sk,
            hour_sk,
            deviceidentifier,
            clientdataid,
            network_sk,
            useridentifier
            )
select i.product_sk,
       b.deviceos_sk,
       d.deviceresolution_sk,
       e.devicelanguage_sk,
       c.devicebrand_sk,
       f.devicesupplier_sk,
       h.location_sk,
       g.date_sk,
       hour(a.date),
       a.deviceid,
       a.id,
       n.network_sk,
       a.useridentifier
from   dc.razor_clientdata a,
       razor_dim_deviceos b,
       razor_dim_devicebrand c,
       razor_dim_deviceresolution d,
       razor_dim_devicelanguage e,
       razor_dim_devicesupplier f,
       razor_dim_date g,
       razor_dim_location h,
       razor_dim_product i,
       razor_dim_network n
where 
       a.osversion = b.deviceos_name
       and a.devicename = c.devicebrand_name
       and a.resolution = d.deviceresolution_name
       and a.language = e.devicelanguage_name
       and a.service_supplier = f.mccmnc
       and date(a.date) = g.datevalue
       and a.country = h.country
       and a.region = h.region
       and a.city = h.city
       and a.productkey = i.product_key
       and i.product_active = 1 and i.channel_active = 1 and i.version_active = 1 
       and a.version = i.version_name
       and a.network = n.networkname
       and a.insertdate between starttime and endtime;

set e = now();
insert into razor_log(op_type,op_name,op_starttime,op_date,affected_rows,duration) 
    values('runfact','razor_fact_clientdata',s,e,row_count(),TIMESTAMPDIFF(SECOND,s,e));


set s = now();
insert into razor_fact_usinglog
           (product_sk,
            date_sk,
            activity_sk,
            session_id,
            duration,
            activities,
            starttime,
            endtime,
            uid)
select p.product_sk,
       d.date_sk,
       a.activity_sk,
       u.session_id,
       u.duration,
       u.activities,
       u.start_millis,
       end_millis,
       u.id
from   dc.razor_clientusinglog u,
       razor_dim_date d,
       razor_dim_product p,
       razor_dim_activity a
where  date(u.start_millis) = d.datevalue and 
       u.appkey = p.product_key 
       and p.product_id=a.product_id 
       and u.version = p.version_name 
       and u.activities = a.activity_name
       and u.insertdate between starttime and endtime;
set e = now();
insert into razor_log(op_type,op_name,op_starttime,op_date,affected_rows,duration) 
    values('runfact','razor_fact_usinglog',s,e,row_count(),TIMESTAMPDIFF(SECOND,s,e));

set s = now();
insert into razor_fact_errorlog
           (date_sk,
            product_sk,
            osversion_sk,
            title_sk,
            deviceidentifier,
            activity,
            time,
            title,
            stacktrace,
            isfix,
            id
            )
select d.date_sk,
       p.product_sk,
       o.deviceos_sk,
       t.title_sk,
       b.devicebrand_sk,
       e.activity,
       e.time,
       e.title,
       e.stacktrace,
       e.isfix,
       e.id
from   dc.razor_errorlog e,
       razor_dim_product p,
       razor_dim_date d,
       razor_dim_deviceos o,
       razor_dim_errortitle t,
       razor_dim_devicebrand b
where  e.appkey = p.product_key
       and e.version = p.version_name
       and date(e.time) = d.datevalue
       and e.os_version = o.deviceos_name
       and e.title = t.title_name
       and e.device = b.devicebrand_name
       and p.product_active = 1 and p.channel_active = 1 and p.version_active = 1
       and e.insertdate between starttime and endtime; 
set e = now();
insert into razor_log(op_type,op_name,op_starttime,op_date,affected_rows,duration) 
    values('runfact','razor_fact_errorlog',s,e,row_count(),TIMESTAMPDIFF(SECOND,s,e));


set s = now();
insert into razor_fact_event
           (event_sk,
            product_sk,
            date_sk,
            deviceid,
            category,
            event,
            label,
            attachment,
            clientdate,
            number)
select e.event_sk,
       p.product_sk,
       d.date_sk,
       f.deviceid,
       f.category,
       f.event,
       f.label,
       f.attachment,
       f.clientdate,
       f.num
from   dc.razor_eventdata f,
       razor_dim_event e,
       razor_dim_product p,
       razor_dim_date d
where  f.event_id = e.event_id
       and e.product_id = p.product_id
       and f.version = p.version_name
       and f.productkey = p.product_key
       and p.product_active = 1 and p.channel_active = 1 and p.version_active = 1
       and date(f.clientdate) = d.datevalue
       and f.insertdate between starttime and endtime;
set e = now();
insert into razor_log(op_type,op_name,op_starttime,op_date,affected_rows,duration) 
    values('runfact','razor_fact_event',s,e,row_count(),TIMESTAMPDIFF(SECOND,s,e));
set s = now();

insert into razor_log(op_type,op_name,op_starttime)
    values('runfact','-----finish runfact-----',now());
    
end;
