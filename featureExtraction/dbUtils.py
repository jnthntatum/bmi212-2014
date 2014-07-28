#!/usr/bin/python3
"""
dbUtils.py
Utilities for accessing a local database that caches downloaded twitter data. 

Handles scraping twitter for the raw features that we use for classification
given a set of users and their cohort (case or control). 
Jon Tatum
jdtatum@cs.stanford.edu
"""


import mysql.connector
import time
import twitterMine
import config
import utils
import twython
import sys

INSERT_USER_TEMPL = \
"""INSERT INTO tusers
    (twitter_user_id, description, followers_count, following_count, screen_name, lang, utc_offset_sec, created_at, statuses_count, location, cohort_id, loaded)
    VALUES(%s, %s, %s, %s, %s, %s, %s, TIMESTAMP(%s), %s, %s, %s, '0');
    """

INSERT_USER_BLOCKED_TEMPL = \
"""INSERT INTO tusers 
    (twitter_user_id, protected)
    VALUES(%s, '1')
    """

INSERT_TWEET_TEMPL = \
"""INSERT INTO  tweets 
    (tweet_id, twitter_user_id, tweet_text, tweet_time)
    VALUES(%s, %s, %s, TIMESTAMP(%s)) 
"""

GET_TWEETS_TEMPL = \
"""SELECT * FROM tweets
        WHERE twitter_user_id = (%s)
        ORDER BY `tweets`.`tweet_time` DESC;
"""

GET_USER_TEMPL = \
"""SELECT * FROM tusers
    WHERE twitter_user_id = (%s)
    ORDER BY created_at DESC;
"""

GET_USERS = """SELECT * FROM tusers;"""

GET_USERS_W_COHORT = \
"""SELECT * FROM tusers
    JOIN cohorts ON tusers.cohort_id = cohorts.cohort_id
    WHERE cohorts.cohort_id in (3);"""


UPDATE_USER_LOADED_TEMPL = \
"""UPDATE tusers 
    set loaded = 1
    where twitter_user_id = "%s"; 
"""  

TWITTER_TIME_FORMAT = "%a %b %d %H:%M:%S %z %Y"
MYSQL_TIME_FORMAT = "%Y-%m-%d %H:%M:%S"

def get_named_rows(cursor):
    names = cursor.column_names
    results = cursor.fetchall()
    for row_idx, row in enumerate(results):
        results[row_idx] = {names[col_idx]:col_val for col_idx, col_val in enumerate(row)}
    return results

def twitter_to_db_time(timestr, offset = None):
    tweet_time_utc = time.strptime(timestr, TWITTER_TIME_FORMAT)
    if offset is None:
        offset = 0
    tweet_time = time.mktime(tweet_time_utc) + offset

    return (time.strftime(MYSQL_TIME_FORMAT, time.localtime(tweet_time)))

def to_user_tuple ( user, cohort_id = None ):
    desc = user['description']
    uid = user['id_str']
    flw_count = user['followers_count']
    flg_count = user['friends_count']
    sts_count = user['statuses_count']
    scr_name = user['screen_name']
    location = user['location']
    cr_at = twitter_to_db_time(user['created_at'])
    utc_offset_sec = user['utc_offset']
    lang = user['lang']
    return uid, desc, flw_count, flg_count, scr_name, lang, utc_offset_sec, cr_at, sts_count, location, cohort_id
    

def to_tuple ( status ):
    text = status['text']
    tweet_id = status['id_str']
    user_id = status['user']['id_str']
    timeoffset_seconds = status['user']['utc_offset']
    tweet_time = status['created_at']
    return ((tweet_id, user_id, text, twitter_to_db_time(tweet_time, timeoffset_seconds)))

def to_tuples (statuses):
    result = deque()
    for status in statuses:
        result.append(to_tuple(status))        
    return list(result)

def setup_mysql_cxn(auth_file = config.DEFAULT_DB):
    user = password = None
    with open(auth_file, 'r') as af:
        line = af.read()
        elements = [x.strip () for x in line.split(',')] 
        user = elements[0]
        password = elements[1]
    cxn = mysql.connector.connect(
        user = user, password = password, 
        host='127.0.0.1', database="bmi212")
    return SafeConnection(cxn)

class SafeConnection(object):
    """
    connection wrapper for use with 'with' statement
    automatically closes so that we don't leave stalled connections
    """

    def __init__(self, cxn):
        self.cxn = cxn
    
    def __enter__(self):
        return self.cxn
    
    def __exit__(self, exc_type, exc_value, traceback):
        utils.debug("Safe closing")
        self.cxn.close() 
    
    def get_connection_object(self):
        return self.cxn

def load_user_ids (fname):
    ids = []
    with open(fname, 'r') as f:
        ids = {}
        for x in f:
            if len (x.strip()) < 0:
                continue
            toks = x.split()
            if len(toks) < 2:
                continue
            ids[toks[0]] = toks[1]
    return ids

def load_user_timeline(cursor, api_client, user):
    for status in twitterMine.get_all_tweets(api_client, user):
        row = to_tuple(status)
        try:
            cursor.execute(INSERT_TWEET_TEMPL, row)
            #utils.debug("Insert %s" % str(row))
        except Exception as e:
            utils.debug("Error on %s" % str(row))
            utils.debug("Error: %s\n" % str(e))
    try:
        utils.debug('marking %s as loaded' % user)
        cursor.execute(UPDATE_USER_LOADED_TEMPL % user)    
        #utils.debug("Insert %s" % str(row))
    except Exception as e:
        utils.debug("Error on %s" % user)
        utils.debug("Error: %s\n" % str(e))

def insert_all_timelines(fname):
    with setup_mysql_cxn() as cxn:
        cursor = cxn.cursor()
        api_client = twitterMine.setup()
        user_ids = load_user_ids(fname)

        for user in user_ids:
            user_loaded = None
            try: 
                cursor.execute("""SELECT loaded FROM 
                    tusers where twitter_user_id = '%s'""" % user)
                user_loaded = get_named_rows(cursor)
            except Exception as e:
                utils.debug("error looking up %s" % user)
                utils.debug("Error message: %s" % str(e))
                user_loaded = []
            
            if len(user_loaded) == 0:
                utils.debug("Error -- user not already fetched %s" % user)
                continue
            elif user_loaded[0]['loaded'] == 1:
                utils.debug("%s, already loaded. Skipping" % user)
                continue
            else:
                try:
                    load_user_timeline(cursor, api_client, user)
                except twython.TwythonAuthError as e:
                    utils.debug('not authed, skipping %s' % user )
                except twython.TwythonError as e:
                    utils.debug("Error: twython error: %s" % str(e))
                    utils.debug("Sleeping 10m")
                    time.sleep(10 * 60)
                    api_client = twitterMine.setup()
                    try:
                        load_user_timeline(cursor, api_client, user)
                    except twython.TwythonAuthError as e:
                        utils.debug('not authed, skipping %s' % user )
                    except twython.TwythonError as e:
                        utils.debug("Error: twython error: %s" % str(e))
                        utils.debug("giving up")
            cxn.commit()
        cursor.close()
        cxn.commit()


def download_and_insert( api_client, cursor, user, cohort_id):
    data = None
    templ = None
    try:
        description = twitterMine.throttle_fn(api_client, twitterMine.get_description, user)
        data = to_user_tuple(description, cohort_id)
        templ = INSERT_USER_TEMPL
    except twython.TwythonAuthError as e:
        utils.debug("not authed. %s is probably protected" % user)
        data = user
        templ = INSERT_USER_BLOCKED_TEMPL
    except twython.TwythonError as e:
        utils.debug("Can't load user -- check if deleted %s" % user)
        return
    
    try:
        cursor.execute(templ, data)
        #utils.debug("Insert: %s" % str(data))
    except Exception as e:
        utils.debug("Error: couldn't insert %s" % str(user))
        utils.debug("Cause: %s\n" % str(e)) 

def insert_all_users( fname ):
    with setup_mysql_cxn() as cxn:
        cursor = cxn.cursor()
        api_client = twitterMine.setup()
        user_ids = load_user_ids(fname)
        print(user_ids)
        for user in user_ids:
            print(user)
            # Check -if we have already downloaded user description
            cohort_id = user_ids[user];
            download_needed = True
            try: 
                cursor.execute(GET_USER_TEMPL % user)
                results = get_named_rows(cursor)
                if len(results) >= 1:
                    utils.debug("User already fetched.")
                    if results[0]['cohort_id'] != str(cohort_id):
                        utils.debug("Updating Cohort for %s" % user)
                        tmpl = "UPDATE tusers SET cohort_id = %s where twitter_user_id = %s";
                        cursor.execute(tmpl % (cohort_id, user))
                        
                    download_needed = False
            except Exception as dbe:
                utils.debug("dbError looking up %s" % str(user)) 
                utils.debug("Info: %s" % str(dbe))
            # Otherwise download and insert
            if download_needed: 
                download_and_insert(api_client, cursor, user, cohort_id)
            cxn.commit()
def test():
    """
    simple unit test
    """
    mytime = time.localtime(time.time())
    with setup_mysql_cnx() as cnx:
        cursor = cxn.cursor()
        try:
            cursor.execute(INSERT_TWEET_TEMPL, ("999999", "9999999", "this is a test", time.strftime(MYSQL_TIME_FORMAT, mytime)))
        except Exception as e:
            pass
        cursor.close()
        cnx.commit()

USAGE = """
USAGE:
    python3 dbutils.py <user list> <cohort>
"""

if __name__ == "__main__":
    if len(sys.argv) >= 2:
        fname = sys.argv[1]    
    else:
        utils.debug(USAGE)
        sys.exit()

    insert_all_users( fname )
    insert_all_timelines(fname)
