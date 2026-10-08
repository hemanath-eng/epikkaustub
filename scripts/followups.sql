select d.id::text as demo_id,
       u.id::text as cd_id, u.name as cd_name, u.email as cd_email,
       to_char(d."demoDateTime" at time zone 'UTC' at time zone 'Asia/Kolkata', 'HH12:MI AM') as slot_ist,
       coalesce(nullif(trim(coalesce(d.address->>'firstName','') || ' ' || coalesce(d.address->>'lastName','')), ''),
                nullif(trim(d.address->>'name'), ''),
                'customer ending ' || right(regexp_replace(d."customerId", '\D', '', 'g'), 4)) as customer,
       coalesce(nullif(trim(d.address->>'phone'), ''), d."customerId") as customer_phone,
       (select string_agg(p.title, ', ') from products p where p."shopifyId"::text = any(d."productIds"::text[])) as product,
       (i.id is not null and not (i.overall_insights::jsonb ? 'analysis_error')
        and i.overall_insights::jsonb ? 'outcome') as has_insight,
       i.overall_insights::jsonb->'outcome'->>'call_result' as call_result,
       i.overall_insights::jsonb->'customer_summary'->>'buying_readiness' as buying_readiness,
       i.overall_insights::jsonb->'customer_summary'->>'sentiment' as sentiment,
       i.overall_insights::jsonb->'customer_summary'->>'key_need' as key_need,
       i.overall_insights::jsonb->'outcome'->>'recommended_next_step' as recommended_next_step,
       i.overall_insights::jsonb->>'one_line_takeaway' as takeaway,
       coalesce(i.is_hot_lead, false) as is_hot_lead,
       case when i.overall_insights::jsonb->'outcome'->>'call_result' = 'qualified' then 2
            when i.overall_insights::jsonb->'outcome'->>'call_result' = 'lost' then -1
            when i.is_hot_lead or i.overall_insights::jsonb->'customer_summary'->>'buying_readiness' = 'ready_to_buy' then 1
            else 0 end as points
from demo_bookings d
join users u on u.id = d."cdId"
left join lateral (select * from demo_insights x where x.demo_id = d.id order by x.created_at desc limit 1) i on true
where d.status = 'COMPLETED'
  and (d."demoDateTime" at time zone 'UTC' at time zone 'Asia/Kolkata')::date = (now() at time zone 'Asia/Kolkata')::date - 1
order by u.name, d."demoDateTime"
