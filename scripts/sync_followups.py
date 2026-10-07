"""Render cron job: refresh epik_sync.followups with yesterday's completed Epik demos.

Reads the Epik app DB (read-only) and rewrites the table in Supabase, which the cloud
pondu-manager agent reads. Only CDE, customer first+last name and product are copied.
No insights, feedback, phones or addresses.

Env: EPIK_DATABASE_URL (read-only source), SUPABASE_DB_URL (target, write),
     CUSTOMER_NAME_SQL (SQL expression for the customer's full name on demo_bookings
     alias `d`, e.g.  trim(d."customerFirstName" || ' ' || d."customerLastName")).
"""
import os
import sys

import psycopg2

SOURCE_SQL = f"""
select d.id::text,
       (d."demoDateTime" at time zone 'UTC' at time zone 'Asia/Kolkata')::date,
       u.id::text, u.name, u.email,
       {os.environ['CUSTOMER_NAME_SQL']},
       (select string_agg(p.title, ', ') from products p where p."shopifyId"::text = any(d."productIds"::text[]))
from demo_bookings d
join users u on u.id = d."cdId"
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
            "insert into epik_sync.followups (demo_id, demo_date, cd_id, cd_name, cd_email, customer_name, product)"
            " values (%s,%s,%s,%s,%s,%s,%s) on conflict (demo_id) do nothing",
            rows,
        )
    print(f"synced {len(rows)} completed demos")
    return 0


if __name__ == "__main__":
    sys.exit(main())
