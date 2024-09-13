
import pandas as pd
df=pd.read_csv('netflix_titles.csv')

import sqlalchemy as sal
engine=sal.create_engine('mssql://RahityaGovindu/master?driver=ODBC+DRIVER+17+FOR+SQL+SERVER')
conn=engine.connect()


df.to_sql('netflix_raw',con=conn,index=False,if_exists='append')

len(df)

df[df.show_id=='s5023']

max(df.cast.dropna().str.len())

df.head()

df.isna().sum()
