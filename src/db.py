# src/db.py
import os
import pymysql
from pymysql.cursors import DictCursor
from dbutils.pooled_db import PooledDB
from dotenv import load_dotenv
from contextlib import contextmanager

load_dotenv()

# 初始化連線池
pool = PooledDB(
    creator = pymysql,
    maxconnections = 10,
    mincached = 2, maxcached = 5,
    blocking = True,
    host = os.getenv("DB_HOST", "127.0.0.1"),
    port = int(os.getenv("DB_PORT", 3306)),
    user = os.getenv("DB_USER", "root"),
    password = os.getenv("DB_PASSWORD", ""),
    database = os.getenv("DB_NAME", "clinic_db"),
    charset = os.getenv("DB_CHARSET", "utf8mb4"),
    cursorclass = DictCursor,
    autocommit = False  # 由我們手動控制交易 (Transaction)
)

@contextmanager
def get_db():
    """ context manager 方便安全獲取連線與自動關閉/回滾"""
    conn = pool.connection()
    cursor = conn.cursor()
    try:
        yield cursor
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        cursor.close()
        conn.close()