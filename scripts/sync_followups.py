"""Render cron job: refresh epik_sync.followups with yesterday's completed Epik demos.

Reads the Epik app DB (read-only) and rewrites the table in Supabase, which the cloud
pondu-manager agent reads. Copied per demo: CDE, demo time (IST), product, and a customer
reference. demo_bookings."customerId" is the customer's phone number, so the reference is
the customer's name when a user or order matches that phone (last 10 digits), otherwise
only "customer ending 1234". Full phone numbers are never copied. No insights or feedback.

Env: EPIK_DATABASE_URL (read-only source), SUPABASE_DB_URL (target, write).
"""
import os
import sys

import psycopg2

SOURCE_SQL = """
with phones as (
  select right(regexp_replace(phone, '\\D', '', 'g'), 10) as p, name, 1 as rank from users
   where phone is not null and name is not null and name <> ''
  union all
  select right(regexp_replace(phone, '\\D', '', 'g'), 10), name, 2 from orders
   where phone is not null and name is not null and name <> '' and name not like '#%'
),
best as (select distinct on (p) p, name from phones order by p, rank)
select d.id::text,
       (d."demoDateTime" at time zone 'UTC' at time zone 'Asia/Kolkata')::date,
       u.id::text, u.name, u.email,
       coalesce(b.name, 'customer ending ' || right(regexp_replace(d."customerId", '\\D', '', 'g'), 4)),
       (select string_agg(p.title, ', ') from products p where p."shopifyId"::text = any(d."productIds"::text[])),
       to_char(d."demoDateTime" at time zone 'UTC' at time zone 'Asia/Kolkata', 'HH12:MI AM')
from demo_bookings d
join users u on u.id = d."cdId"
left join best b on b.p = right(regexp_replace(d."customerId", '\\D', '', 'g'), 10)
where d.status = 'COMPLETED'
  and (d."demoDateTime" at time zone 'UTC' at time zone 'Asia/Kolkata')::date
      = (now() at time zone 'Asia/Kolkata')::date - 1
"""


def main() -> int:
    with psycopg2.connect(os.environ["EPIK_DATABASE_URL"]) as src:
        src.set_session(readonly=True)
        with src.cursor() as cur:
            cur.execute(SOURCE_SQL)
            rows = cur.fetchall()
    with psycopg2.connect(os.environ["SUPABASE_DB_URL"]) as dst, dst.cursor() as cur:
        # Keep messaged_at for demos already messaged so a re-run never double-sends.
        cur.execute("delete from epik_sync.followups where messaged_at is null or demo_date < current_date - 3")
        cur.executemany(
            "insert into epik_sync.followups (demo_id, demo_date, cd_id, cd_name, cd_email, customer_name, product, demo_time_ist)"
            " values (%s,%s,%s,%s,%s,%s,%s,%s) on conflict (demo_id) do nothing",
            rows,
        )
    print(f"synced {len(rows)} completed demos")
    return 0


if __name__ == "__main__":
    sys.exit(main())
