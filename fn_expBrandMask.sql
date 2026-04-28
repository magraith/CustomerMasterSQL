/***************************************************************************************************
        NAME:   fn_brandMask
        VERSION: 2

        COMMENTS: expands the brandmask into the descriptions of the constituent brands
        
        4/27/26     v1 it works!
        4/28/26     v2 add permission grants for other users    

**************************************************************************************************/

create OR REPLACE function CUST_ADMIN.FN_EXPBRANDMASK(mask IN NUMBER) 
    RETURN string
    IS brandExp VARCHAR(100);
    BEGIN
        select replace(rtrim(CONCAT(CONCAT(CONCAT( CONCAT(CONCAT(
                concat(CASE WHEN brand1_brand is not null THEN concat(brand1_brand,' ') ELSE '' END,
                CASE WHEN brand3_brand  is not null then concat(brand3_brand,' ') ELSE '' END), 
                CASE WHEN brand4_brand  is not null then concat(brand4_brand,' ') ELSE '' END),
                CASE WHEN brand5_brand  is not null then concat(brand5_brand,' ') ELSE '' END),
                CASE WHEN brand6_brand  is not null then concat(brand6_brand,' ') ELSE '' END),
                CASE WHEN brand7_brand  is not null then concat(brand7_brand,' ') ELSE '' END),
                CASE WHEN brand9_brand  is not null then concat(brand9_brand,' ') ELSE '' END) ),' ','|')
                INTO brandExp
        FROM (   select * from (SELECT gm.local_id as brand_id, gm.foreign_id
            FROM cust_admin.generic_metadata gm
            WHERE gm.field_name='BRAND_ID' 
            and BITAND(mask,to_number(gm.display_order))= gm.display_order
            )   
            PIVOT (
                    min(foreign_id) Brand
                    FOR brand_id
                    IN ( 1 as brand1, 3 as brand3, 4 as brand4, 5 as brand5, 6 as brand6, 7 as brand7,9 as brand9 )
                    --(select DISTINCT FOREIGN_ID from cust_admin.generic_Metadata where field_name='BRAND_ID')
            )
         );
         RETURN brandExp;
    END;
    

  GRANT EXECUTE ON "CUST_ADMIN"."FN_EXPBRANDMASK" TO "CUST_FULL";
  GRANT EXECUTE ON "CUST_ADMIN"."FN_EXPBRANDMASK" TO "CUST_READ";    

/*    
    select key, email_address,brand_mask, cust_admin.fn_expBrandMask(p.brand_Mask) as brands
    from  person p
    where brand_mask> 10;

SELECT * FROM CUST_ADMIN.GENERIC_METADATA 
-- where foreign_id='tcprefcenterpub';
WHERE FIELD_NAME = 'BRAND_ID';

select p.key, p.email_address, brand_mask, notes, local_id, foreign_id
from cust_admin.person p 
join cust_admin.generic_metadata gmb
on bitand(p.brand_mask,TO_NUMBER(gmb.display_order) ) = to_number(gmb.display_order)
and field_name='BRAND_ID' and brand_mask>10;
*/