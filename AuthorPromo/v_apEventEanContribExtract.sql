DELIMITER //
  DROP VIEW if exists v_apEventEanContribExtract;

/*
v_apEventEanContribExtract

DESCRIPTION: 	used to feed author promo event data to EventBuilder

USER	DATE		COMMENT
----	----		-------
fdiym	30 July 	swap eventtype for web category

*/

CREATE VIEW v_apEventEanContribExtract
AS  

SELECT distinct  e.Event_ID as EventID,
							es.`status`,
                    e.store_num as StoreNum,
                    RTRIM(e.event_desc) as EventName,
                    et.event_desc as EventType,
                    i.category_desc as EventGenre,
                    DATE_FORMAT(e.event_date,"%Y-%m-%d") as EventDate,  -- yyyy-mm-dd hh:mi:ss(24h)
                    TIME_FORMAT(e.event_time, '%l:%i%p')  as EventTime, 
                    t.item_rank,
                    CONVERT(t.item_num, signed) as EventEAN, 
                    e.tsmodified as LastModified,
                    CONVErT(coalesce(e.on_website,0), signed) as on_Website ,
                    CONVErT(coalesce(e.off_site,0), signed) AS off_Site, -- this means not at a BN store 
                    eic.contributor_rank,
						  CONVERT(c.contributor_id, SIGNED) AS contrib_id, 
						  RTRIM(c.first_name) AS firstName,
                    RTRIM(c.last_name) AS lastName,
                        0 as EventBriteId,
                        e.alt_address_1, e.alt_address_2, e.alt_city, e.alt_state,e.alt_zipcode
FROM event_detail e   inner join event_header r on e.event_header_id = r.event_header_id
                      inner join event_detail_item  t on t.event_id = e.event_id
                      INNER JOIN item i on i.item_num= t.item_num
                      LEFT  JOIN event_type et ON et.event_type_id = e.event_type_id
                      LEFT JOIN event_status es ON e.status_id = es.id
                      LEFT JOIN event_item_contributor eic ON eic.event_id = e.event_id AND eic.item_num = t.item_num
                      LEFT JOIN contributor c ON eic.contributor_id = c.contributor_id
                      left join web_category ec on e.event_web_category_id = ec.id
                WHERE e.event_date between curdate() and DATE_ADD(curdate(), INTERVAL 6 MONTH) 
                      and e.status_id IN (5,1,8)
                      AND e.event_id IN 
								  (SELECT ed.event_id -- ,ed.event_desc, event_date, status_id , item_num
								  FROM event_detail ed left JOIN 
								  event_detail_item edi ON ed.event_id = edi.event_id
								  WHERE 	ed.tsmodified > ADDDATE(CURDATE(),-1) -- change to -1
								OR edi.tsmodified> ADDDATE(CURDATE(),-1) -- CHANGE TO -1
	                        ) 	
					ORDER BY e.event_id,t.item_rank, eic.contributor_rank
;
//
DELIMITER ;