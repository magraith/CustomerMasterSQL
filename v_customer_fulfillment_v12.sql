    /**************************************************************************************************
        NAME:   v_customer_fulfillment 
        VERSION: 12

        COMMENTS: 
        v12     use the  WITH command for certain subqueries.   12/12/2025 imcgrath
        

**************************************************************************************************/
CREATE OR REPLACE VIEW CUST_ADMIN.V_CUSTOMER_FULFILLMENT as
WITH mercury_keys AS (
  SELECT person_key, MAX(created_at) AS created, MIN(external_key) AS minmerc
  FROM cust_admin.person_ext_key
  WHERE external_src = 'mercury'
    AND COALESCE(valid_through, SYSDATE + 1) > SYSDATE
  GROUP BY person_key
),
atg_keys AS (
  SELECT person_key, MAX(created_at) AS created, MAX(external_key) AS extkey
  FROM cust_admin.person_ext_key
  WHERE external_src = 'atg'
    AND COALESCE(valid_through, SYSDATE + 1) > SYSDATE
  GROUP BY person_key
),
address AS (
SELECT pa.person_key, MAX(pa.ID) AS maxid, case when pa.address_type_id = 1 then 1 else 2 end as address_type_id, case when pa.address_type_id = 1 then 'Billing Address' else 'Shipping Address' end as addressType
FROM cust_admin.person_address pa
WHERE pa.preferred_flag = 'Y'
AND pa.active_flag = 'Y'
GROUP BY pa.person_key,  case when pa.address_type_id = 1 then 1 else 2 end, case when pa.address_type_id = 1 then 'Billing Address' else 'Shipping Address' end  
)
    
SELECT      peka.external_key  as customer_id,
          pek.external_key          digital_mercury_id,
          bnu.email_address          login,
          bnu.email_address           email,
          bnu.keyname_prefix    first_name,
          bnu.keyname       last_name,
        case when dci.person_key is not     null then    dci.address1   else dcq.address1 end  addr_line1,
         case when dci.person_key is not     null then    dci.address2  else dcq.address2 end  addr_line2,
         case when dci.person_key is not     null then     dci.city     else dcq.city end city,
         case when dci.person_key is not     null then     dci.region   else dcq.region end     state,
         case when dci.person_key is not     null then     dci.postal_code   else dcq.postal_code end  postal_code,
         case when dci.person_key is not     null then     dci.country  else dcq.country  end  country,
         case when dci.person_key is not     null then     dci.phone else dcq.phone   end  phone,
         NVL(addk.addressType,addj.addressType) AS             address_type,

         pa.attribute_val  as has_ae_account,
        bnu.key as customer_key,
        gmp.description as person_type,
        bnu.brand_mask,
        bnu.standardized_key

FROM cust_admin.person bnu
left join cust_admin.person_attribute pa 
        on pa.person_key = bnu.key
        and pa.attribute_key='dabAcctFlag'
left join mercury_keys m
ON M.person_key = bnu.key
left join (select  person_key,external_key, created_at
        FROM cust_admin.person_ext_key 
        WHERE external_src='mercury'
        and coalesce(valid_through,sysdate+1) >sysdate
        ) pek 
    on pek.person_key = bnu.key
    and pek.created_at = m.created
    and pek.external_key = minmerc
left join atg_keys a
    ON a.person_key = bnu.key
LEFT JOIN  (select  k.person_key,k.external_key, k.created_at--, k.VALID_THROUGH
        FROM cust_admin.person_ext_key k
        WHERE k.external_src='atg'
        AND coalesce(k.valid_through,sysdate+1) >sysdate
        ) peka 
        on peka.person_key = bnu.key
        and peka.created_at = a.created
        and peka.external_key = extkey
left join cust_admin.generic_metadata gmp
on gmp.local_id = bnu.person_type_id
and gmp.field_Name = 'PERSON_TYPE_ID'

LEFT JOIN ( SELECT * 
             FROM address
             where address_type_id = 1
             ) addk
on addk.person_key = bnu.key
left join cust_admin.person_address dci 
    on dci.person_key = bnu.key 
    and dci.address_type_id =1
    and dci.preferred_flag='Y'
    and dci.id = addk.maxid
left join (select * from address  where address_type_id =2 ) addj 
    on addj.person_key=bnu.key 
left join cust_admin.person_address dcq 
    on dcq.person_key = bnu.key 
    and dcq.address_type_id >1
    and dcq.preferred_flag='Y'
    AND dcq.id = ADDJ.maxid
;

  GRANT SELECT ON "CUST_ADMIN"."V_CUSTOMER_FULFILLMENT2" TO "CUST_FULL";
  GRANT SELECT ON "CUST_ADMIN"."V_CUSTOMER_FULFILLMENT2" TO "CUST_READ";
  
  /*
    select * from cust_admin.v_customer_fulfillment2 where digital_mercury_id is not null ;
  */
  
/*  
CREATE INDEX CUST_ADMIN.IDX_PEK_CREATED_AT_REV  ON CUST_ADMIN.PERSON_EXT_KEY ( "PERSON_KEY","CREATED_AT")
;

CREATE INDEX CUST_ADMIN.IDX_PEK_CREATED_AT  ON CUST_ADMIN.PERSON_EXT_KEY ("CREATED_AT", "PERSON_KEY")
;
*/