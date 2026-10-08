select d.id::text as demo_id,
       u.id::text as cd_id, u.name as cd_name, u.email as cd_email,
       to_char(d."demoDateTime" at time zone 'UTC' at time zone 'Asia/Kolkata', 'HH12:MI AM') as slot_ist,
       coalesce(nullif(trim(coalesce(d.address->>'firstName','') || ' ' || coalesce(d.address->>'lastName','')), ''),
                nullif(trim(d.address->>'name'), ''),
                'customer ending ' || right(regexp_replace(d."customerId", '\D', '', 'g'), 4)) as customer,
       (select string_agg(p.title, ', ') from products p where p."shopifyId"::text = any(d."productIds"::text[])) as product
from demo_bookings d
join users u on u.id = d."cdId"
where d.status = 'COMPLETED'
  and (d."demoDateTime" at time zone 'UTC' at time zone 'Asia/Kolkata')::date = (now() at time zone 'Asia/Kolkata')::date - 1
order by u.name, d."demoDateTime"
