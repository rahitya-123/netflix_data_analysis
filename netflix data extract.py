#!/usr/bin/env python
# coding: utf-8

# In[3]:


import pandas as pd
df=pd.read_csv('netflix_titles.csv')


# In[26]:


import sqlalchemy as sal
engine=sal.create_engine('mssql://RahityaGovindu/master?driver=ODBC+DRIVER+17+FOR+SQL+SERVER')
conn=engine.connect()


# In[27]:


df.to_sql('netflix_raw',con=conn,index=False,if_exists='append')


# In[6]:


len(df)


# In[8]:


df[df.show_id=='s5023']


# In[12]:


max(df.cast.dropna().str.len())


# In[28]:


df.head()


# In[30]:


df.isna().sum()


# In[ ]:




