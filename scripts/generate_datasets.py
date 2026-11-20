"""Generate fictional banking datasets with deliberate data-quality problems. Seeded = reproducible."""
import csv, json, random, sys, os
from datetime import date, datetime, timedelta
random.seed(42)
OUT = sys.argv[1]; os.makedirs(OUT, exist_ok=True)

FIRST = ["Aarav","Vivaan","Aditya","Vihaan","Arjun","Sai","Reyansh","Krishna","Ishaan","Rohan","Ananya","Diya","Aadhya","Saanvi","Pari","Myra","Anika","Navya","Kiara","Riya",
         "Rahul","Priya","Amit","Sneha","Karan","Pooja","Nikhil","Meera","Varun","Kavya","Siddharth","Tanvi","Harsh","Isha","Manav","Neha","Yash","Shreya","Dev","Aditi"]
LAST = ["Sharma","Verma","Patel","Iyer","Reddy","Nair","Gupta","Kulkarni","Deshmukh","Joshi","Mehta","Shah","Rao","Pillai","Bose","Das","Kapoor","Malhotra","Chopra","Bhat"]
CITIES = [("Mumbai","Maharashtra"),("Pune","Maharashtra"),("Nagpur","Maharashtra"),("Bengaluru","Karnataka"),("Chennai","Tamil Nadu"),
          ("Hyderabad","Telangana"),("Delhi","Delhi"),("Kolkata","West Bengal"),("Ahmedabad","Gujarat"),("Jaipur","Rajasthan")]

def d(s): return datetime.strptime(s, "%Y-%m-%d").date()
def rdate(a, b): return a + timedelta(days=random.randint(0, (b - a).days))

# ---------------- branches (15 + issues) ----------------
branches = []
for i, (city, state) in enumerate(CITIES * 2, start=1):
    if i > 15: break
    branches.append({"branch_id": f"BR{i:03d}", "branch_name": f"{city} {'Main' if i<=10 else 'East'} Branch",
                     "city": city, "state": state, "ifsc_code": f"FAKE0{i:06d}", "opened_date": str(rdate(d("2005-01-01"), d("2020-12-31"))),
                     "manager_name": f"{random.choice(FIRST)} {random.choice(LAST)}"})
branches[13]["manager_name"] = ""            # missing manager
branches.append(dict(branches[2]))           # exact duplicate row
branch_ids = [b["branch_id"] for b in branches[:15]]

# ---------------- customers (300 + issues) ----------------
customers = []
for i in range(1, 301):
    fn, ln = random.choice(FIRST), random.choice(LAST); city, state = random.choice(CITIES)
    customers.append({"customer_id": f"C{i:05d}", "first_name": fn, "last_name": ln,
        "date_of_birth": str(rdate(d("1950-01-01"), d("2004-12-31"))), "gender": random.choice(["M","F"]),
        "email": f"{fn.lower()}.{ln.lower()}{i}@example.com", "phone": f"+91-9{random.randint(100000000,999999999)}",
        "city": city, "state": state, "customer_segment": random.choices(["RETAIL","PREMIUM","CORPORATE"], [70,22,8])[0],
        "kyc_status": random.choices(["VERIFIED","PENDING","REJECTED"], [85,12,3])[0], "home_branch_id": random.choice(branch_ids),
        "created_date": str(rdate(d("2015-01-01"), d("2025-12-31")))})
customers[4]["email"] = "not-an-email"; customers[9]["email"] = ""; customers[14]["phone"] = ""
customers[19]["date_of_birth"] = "1990-02-30"                       # invalid date
customers[24]["date_of_birth"] = "2030-05-01"                       # future DOB
customers[29]["first_name"] = "  rahul "; customers[29]["last_name"] = "SHARMA "   # spaces / case
customers[34]["gender"] = "Male"; customers[39]["gender"] = ""     # non-standard
customers[44]["kyc_status"] = "verified"                            # lower case
customers[49]["home_branch_id"] = "BR999"                           # orphan FK
customers[54]["date_of_birth"] = "15/08/1985"                       # other format
customers.append(dict(customers[59]))                               # exact duplicate
dup = dict(customers[64]); dup["phone"] = "+91-9000000001"; customers.append(dup)   # same id, changed phone
customers.append({**customers[0], "customer_id": "", "first_name": "Ghost"})       # missing PK
cust_ids = [f"C{i:05d}" for i in range(1, 301)]

# ---------------- accounts (450 + issues) ----------------
accounts = []
for i in range(1, 451):
    cid = cust_ids[(i - 1) % 300] if i <= 300 else random.choice(cust_ids)
    atype = random.choices(["SAVINGS","CURRENT","SALARY","FIXED_DEPOSIT"], [55,20,15,10])[0]
    bal = round(random.uniform(500, 250000 if atype != "FIXED_DEPOSIT" else 1000000), 2)
    accounts.append({"account_id": f"A{i:06d}", "customer_id": cid, "branch_id": random.choice(branch_ids), "account_type": atype,
        "currency": "INR", "open_date": str(rdate(d("2016-01-01"), d("2025-12-31"))),
        "status": random.choices(["ACTIVE","DORMANT","CLOSED"], [85,10,5])[0], "current_balance": bal,
        "interest_rate": {"SAVINGS":3.5,"CURRENT":0.0,"SALARY":3.0,"FIXED_DEPOSIT":7.1}[atype]})
accounts[7]["customer_id"] = "C99999"; accounts[17]["current_balance"] = -2500.00
accounts[27]["account_type"] = "savings "; accounts[37]["status"] = ""; accounts[47]["currency"] = "USD"
accounts[57]["open_date"] = "2026-13-01"; accounts[67]["current_balance"] = ""
accounts.append(dict(accounts[77]))
acc = [a for a in accounts[:450] if a["status"] != "CLOSED"]
acc_ids = [a["account_id"] for a in acc]

# ---------------- transactions (3000 + issues), Jan-Mar 2026 ----------------
CHANNELS = ["ATM","UPI","NEFT","IMPS","BRANCH","NETBANKING","POS"]
transactions = []
for i in range(1, 3001):
    ttype = random.choices(["DEPOSIT","WITHDRAWAL","TRANSFER_OUT","TRANSFER_IN"], [30,30,25,15])[0]
    ch = random.choice(CHANNELS if ttype != "DEPOSIT" else ["ATM","BRANCH","NEFT","UPI"])
    ts = datetime(2026,1,1) + timedelta(minutes=random.randint(0, 89*24*60))
    amt = round(random.choice([random.uniform(100, 5000), random.uniform(5000, 50000), random.uniform(50000, 300000)]), 2)
    transactions.append({"transaction_id": f"T{i:07d}", "account_id": random.choice(acc_ids), "transaction_ts": ts.strftime("%Y-%m-%d %H:%M:%S"),
        "transaction_type": ttype, "amount": amt, "currency": "INR", "channel": ch,
        "counterparty_account": random.choice(acc_ids) if ttype.startswith("TRANSFER") else "",
        "status": random.choices(["SUCCESS","FAILED","REVERSED"], [94,4,2])[0], "description": f"{ttype.title().replace('_',' ')} via {ch}"})
for k in (11, 211, 411): transactions[k]["amount"] = -abs(transactions[k]["amount"])
for k in (21, 221): transactions[k]["amount"] = 0
for k in (31, 231): transactions[k]["amount"] = ""
transactions[41]["account_id"] = "A999999"; transactions[51]["account_id"] = ""
transactions[61]["transaction_ts"] = "2026-02-30 10:15:00"; transactions[71]["transaction_ts"] = "15-01-2026 09:30"
transactions[81]["transaction_type"] = "deposit"; transactions[91]["transaction_type"] = "UNKNOWN"
transactions[101]["amount"] = "1,250.50"; transactions[111]["currency"] = ""
for k in (121, 131, 141, 151, 161): transactions.append(dict(transactions[k]))      # exact duplicates
late = dict(transactions[171]); late["status"] = "REVERSED"; transactions.append(late)  # same id, status changed
random.shuffle(transactions)

# ---------------- loans (120 + issues) ----------------
loans = []
for i in range(1, 121):
    ltype = random.choices(["HOME","PERSONAL","AUTO","EDUCATION","BUSINESS"], [30,30,20,10,10])[0]
    principal = round({"HOME": random.uniform(1500000, 9000000), "PERSONAL": random.uniform(50000, 1500000), "AUTO": random.uniform(300000, 2500000),
                       "EDUCATION": random.uniform(200000, 3000000), "BUSINESS": random.uniform(500000, 10000000)}[ltype], 2)
    tenure = random.choice([12,24,36,60,120,180,240]); rate = {"HOME":8.5,"PERSONAL":12.5,"AUTO":9.2,"EDUCATION":10.0,"BUSINESS":11.0}[ltype]
    start = rdate(d("2019-01-01"), d("2025-12-31")); r = rate/1200
    emi = round(principal * r * (1+r)**tenure / ((1+r)**tenure - 1), 2)
    paid = min(tenure, max(0, (2026-start.year)*12 - start.month + 3))
    outstanding = round(max(0, principal - emi*paid*0.6), 2)
    loans.append({"loan_id": f"L{i:05d}", "customer_id": random.choice(cust_ids), "branch_id": random.choice(branch_ids), "loan_type": ltype,
        "principal_amount": principal, "interest_rate": rate, "tenure_months": tenure, "start_date": str(start), "emi_amount": emi,
        "outstanding_amount": outstanding, "loan_status": random.choices(["ACTIVE","CLOSED","DEFAULTED","NPA"], [75,15,7,3])[0],
        "days_past_due": random.choices([0, random.randint(1,30), random.randint(31,90), random.randint(91,365)], [80,10,6,4])[0]})
loans[5]["customer_id"] = "C88888"; loans[15]["principal_amount"] = -500000; loans[25]["interest_rate"] = ""
loans[35]["outstanding_amount"] = loans[35]["principal_amount"] * 2; loans[45]["start_date"] = "2031-01-01"
loans.append(dict(loans[55]))

# ---------------- credit card transactions (1500 + issues) ----------------
cards = {cid: f"CARD{n:06d}" for n, cid in enumerate(random.sample(cust_ids, 150), start=1)}
MERCH = [("Flipkart","SHOPPING"),("Amazon","SHOPPING"),("Swiggy","FOOD"),("Zomato","FOOD"),("BigBasket","GROCERY"),("IndianOil","FUEL"),
         ("MakeMyTrip","TRAVEL"),("IRCTC","TRAVEL"),("Apollo Pharmacy","HEALTH"),("PVR Cinemas","ENTERTAINMENT"),("Croma","ELECTRONICS")]
cct = []
for i in range(1, 1501):
    cid = random.choice(list(cards)); m, cat = random.choice(MERCH)
    ts = datetime(2026,1,1) + timedelta(minutes=random.randint(0, 89*24*60))
    cct.append({"cc_txn_id": f"CC{i:07d}", "card_id": cards[cid], "customer_id": cid, "txn_ts": ts.strftime("%Y-%m-%d %H:%M:%S"),
        "merchant_name": m, "merchant_category": cat, "amount": round(random.uniform(99, 45000), 2), "currency": "INR",
        "city": random.choice(CITIES)[0], "status": random.choices(["APPROVED","DECLINED"], [95,5])[0], "is_international": random.choices(["N","Y"], [96,4])[0]})
cct[3]["amount"] = -1200; cct[13]["merchant_category"] = ""; cct[23]["customer_id"] = "C77777"; cct[33]["txn_ts"] = ""
cct[43]["status"] = "approved"; cct[53]["amount"] = "abc"
for k in (63, 73, 83): cct.append(dict(cct[k]))

# ---------------- payments.json (600 + issues), nested JSON ----------------
payments = []
for i in range(1, 601):
    a = random.choice(acc_ids); ts = datetime(2026,1,1) + timedelta(minutes=random.randint(0, 89*24*60))
    kind = random.choices(["BILL_PAYMENT","LOAN_EMI","CREDIT_CARD_BILL"], [50,30,20])[0]
    payee = {"BILL_PAYMENT": random.choice(["MSEDCL Electricity","Airtel Postpaid","Jio Fiber","Mahanagar Gas","LIC Premium"]),
             "LOAN_EMI": random.choice([l["loan_id"] for l in loans[:120]]), "CREDIT_CARD_BILL": random.choice(list(cards.values()))}[kind]
    payments.append({"payment_id": f"P{i:06d}", "payment_type": kind, "payment_ts": ts.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "payer": {"customer_id": next(x["customer_id"] for x in accounts if x["account_id"] == a), "account_id": a},
        "payee": {"reference": payee, "category": kind},
        "amount": {"value": round(random.uniform(200, 60000), 2), "currency": "INR"},
        "mode": random.choice(["UPI","NETBANKING","AUTO_DEBIT","NEFT"]), "status": random.choices(["SUCCESS","FAILED","PENDING"], [90,6,4])[0]})
payments[7]["amount"]["value"] = -300; payments[17]["payer"]["account_id"] = None; payments[27]["payment_ts"] = "2026/02/10 10:00"
payments[37]["status"] = "success"; del payments[47]["mode"]; payments[57]["amount"] = {"value": "NaN", "currency": "INR"}
payments.append(json.loads(json.dumps(payments[67])))

def write_csv(name, rows):
    with open(os.path.join(OUT, name), "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
    print(f"{name}: {len(rows)} rows")
write_csv("branches.csv", branches); write_csv("customers.csv", customers); write_csv("accounts.csv", accounts)
write_csv("transactions.csv", transactions); write_csv("loans.csv", loans); write_csv("credit_card_transactions.csv", cct)
with open(os.path.join(OUT, "payments.json"), "w", encoding="utf-8") as f:
    for p in payments: f.write(json.dumps(p) + "\n")      # JSON Lines: one object per line (Spark default)
print(f"payments.json: {len(payments)} records (JSON Lines)")
