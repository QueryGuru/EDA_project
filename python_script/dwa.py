import pandas as pd
from sqlalchemy import create_engine
from urllib.parse import quote_plus

# --- 🛠 Configuration ---
csv_base_path = r'C:\Users\v-jakapo\Desktop\Dataset\sql-data-analytics-project\sql-data-analytics-project\datasets\csv-files'
mysql_user = 'root'
raw_password = 'pass@123'  # replace with your actual password
mysql_password = quote_plus(raw_password)
mysql_host = 'localhost'
mysql_port = 3306
mysql_database = 'DataWarehouseAnalytics'

# --- 🚀 SQLAlchemy engine -
engine = create_engine(f"mysql+pymysql://{mysql_user}:{mysql_password}@{mysql_host}:{mysql_port}/{mysql_database}")

# --- 🧾 Load CSVs into MySQL ---
csv_to_table = {
    'gold.dim_customers.csv': 'gold_dim_customers',
    'gold.dim_products.csv': 'gold_dim_products',
    'gold.fact_sales.csv': 'gold_fact_sales'
}

for csv_file, table_name in csv_to_table.items():
    file_path = f"{csv_base_path}\\{csv_file}"
    df = pd.read_csv(file_path)
    df.to_sql(name=table_name, con=engine, if_exists='replace', index=False)
    print(f"✅ Imported {csv_file} into table {table_name}")

print("🎉 All files successfully loaded.")
