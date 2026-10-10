import sqlite3,json,pathlib
c=sqlite3.connect(':memory:');c.execute('PRAGMA foreign_keys=ON')
c.executescript(pathlib.Path('drizzle/0000_salty_domino.sql').read_text())
c.execute("INSERT INTO products VALUES('p','p','{}','published',0)")
c.execute("INSERT INTO variants VALUES('v','p','SKU',1000,3,'{}')")
coupon={'active':True,'minimum':0,'starts':'','expires':''}
c.execute('INSERT INTO coupons VALUES(?,?,?,?,?)',('c','TEST',json.dumps(coupon),0,1));c.commit()
checks=0
def test(name,fn):
 global checks
 fn();checks+=1;print('PASS',name)
def order(id,coupon=None,q=1,price=1000):
 with c:
  c.execute('INSERT INTO orders(id,number,idempotency,fingerprint,phone,customer,subtotal,discount,shipping,total,created_at,coupon_id) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)',(id,id,id,'fp','03001234567','{}',price*q,0,0,price*q,'2026-10-09',coupon))
  c.execute('INSERT INTO order_items VALUES(?,?,?,?,?,?)',(id,id,'v',q,price,'{}'))
def eq(query,expected):assert c.execute(query).fetchone()[0]==expected

def reserve():order('one','c',2);eq("SELECT stock FROM variants WHERE id='v'",1)
test('Order reserves stock inside transaction',reserve)
def out():
 try:order('two',None,2);assert False
 except sqlite3.IntegrityError:pass
 eq("SELECT COUNT(*) FROM orders WHERE id='two'",0);eq("SELECT stock FROM variants",1)
test('Oversell aborts and rolls back order',out)
def price():
 try:order('wrong',None,1,1);assert False
 except sqlite3.IntegrityError:pass
 eq("SELECT COUNT(*) FROM orders WHERE id='wrong'",0)
test('Price change blocks stale order',price)
def duplicate():
 try:order('one');assert False
 except sqlite3.IntegrityError:pass
 eq("SELECT stock FROM variants",1)
test('Database uniqueness prevents duplicate order',duplicate)
def limit():
 try:order('coupon2','c');assert False
 except sqlite3.IntegrityError:pass
 eq("SELECT COUNT(*) FROM orders WHERE id='coupon2'",0)
test('Coupon usage is atomic',limit)
def cancel():
 c.execute("UPDATE orders SET status='Cancelled' WHERE id='one'");c.commit();eq('SELECT stock FROM variants',3);c.execute("UPDATE orders SET status='Cancelled' WHERE id='one'");c.commit();eq('SELECT stock FROM variants',3)
test('Cancellation restores inventory exactly once',cancel)
def returns():
 order('return');c.execute("UPDATE orders SET status='Returned' WHERE id='return'");c.commit();eq('SELECT stock FROM variants',3);eq("SELECT released FROM orders WHERE id='return'",1)
test('Return restores inventory once',returns)
def couponrollback():
 c.execute("UPDATE coupons SET used=0");c.commit()
 try:order('rollback','c',9);assert False
 except sqlite3.IntegrityError:pass
 eq('SELECT used FROM coupons',0)
test('Failed order rolls back coupon reservation',couponrollback)
def foreign():
 try:c.execute("DELETE FROM variants WHERE id='v'");c.commit();assert False
 except sqlite3.IntegrityError:c.rollback()
test('Order history protects referenced variant',foreign)
print(checks,'database checks passed.')
