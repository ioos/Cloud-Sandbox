from datetime import datetime
from datetime import timedelta

cdate = "20250905"
hh = "18"
ofs = "cbofs"

datetimeObj = datetime.strptime(cdate+hh, '%Y%m%d%H')+timedelta(hours=6)
ncdate = datetimeObj.strftime('%Y%m%d')
ncyc = datetimeObj.strftime('%H')

print(f"ncdate: {ncdate}")
print(f"ncyc: {ncyc}")

npfx = '{}.t{}z.{}'.format(ofs,ncyc,ncdate)
print(f"npfx: {npfx}")
