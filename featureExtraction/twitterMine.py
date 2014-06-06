#!/usr/bin/python3
"""
twitterMine.py

Utilities for mining twitterData. Mostly wrappers for twython.

Jon Tatum 
jdtatum@cs.stanford
"""

import utils
import twython
import config
import time
import utils
from collections import deque

# ===================
# simple module test
# ===================
def main():
	# should change these to use a dynamically loaded file
	drugs = utils.load_drug_file()
	creds = utils.load_credentials_file()
	api_client = twython.Twython(*creds)

	drugs_to_search = [ '"' + el + '"' if el.find(' ') >= 0 else el for el in drugs['risperidone'] ]
	query = utils.url_encode( ' OR '.join(drugs_to_search) ) 

	print(query)

	# additional parameters can control date range, guessed language, etc. 
	results = api_client.search( q = query, count = 100, lang="en")

	for result in results['statuses']:
		print (result['text']) 
		print ("")

	tl = get_timeline(api_client, '1265683232')
	tlt = [t['text'] for t in tl]
	print (tlt)
	
def setup(file = config.DEFAULT_CRED):
	creds = utils.load_credentials_file()
	api_client = twython.Twython(*creds)
	return api_client

# =========================
# wrappers for api calls
# mostly just wrapping twython functions
# useful for rate limiting
# =========================

def get_timeline(client, uid, max_id = None, since_id = None):
	return client.get_user_timeline(user_id = uid, max_id = max_id, count = 200)
	
def get_followers( client, uid ):
	return client.get_followers_ids( user_id = uid )['ids']

def get_following( client, uid ):
	return client.get_friends_ids( user_id = uid )['ids']

def get_followers_and_following( client, uid ):
	a = get_followers( client, uid )
	b = get_following( client, uid )
	return set(a) & set(b)

def get_description( client, user_id ):
	result = client.show_user( user_id = user_id )
	return result

def look_up_user( client, screen_name ):
	return client.look_up_user(screen_name = screen_name)


# =================
# helper functions for things that aren't available in api
# =================

def throttle_fn( client, fn, *args ):
	"""
	prevents using up all of the query allowance
	example: throttle_fn( client, get_description, user_id)
	"""
	result = fn( client, *args )
	left = int(client.get_lastfunction_header('x-rate-limit-remaining'))
	if (left < 5):
		utils.debug("Warning: throttling function")
		if left <= 1:
			utils.debug("sleeping for 15m")
			time.sleep(15 * 60)
		elif left <= 2:
			utils.debug("sleeping for 8m") 
			time.sleep(8 * 60)
		elif left <= 3:
			utils.debug("sleeping for 4m")
			time.sleep(4 * 60)
		elif left <= 4:
			utils.debug("sleeping for 2m")
			time.sleep(2 * 60)
		else:
			utils.debug("sleeping for 1m")
			time.sleep(60)
	return result

def get_all_tweets(client, uid, max_id = None, since_id = None, max_count = 10000):
	sublist = [None]
	total = 0
	max_id = None
	while len(sublist) > 0 and total < max_count:
		sublist = throttle_fn(client, get_timeline, uid, max_id, since_id)
		total += len(sublist)
		max_id = None
		# compute next max_id
		for tweet in sublist:
			tid = int(tweet['id'])
			if max_id is None or tid <= max_id:
				max_id = tid - 1 
			yield(tweet)

def get_full_timeline(client, uid, max_count = 10000):
	result = [tweet for tweet in get_all_tweets(client, uid, max_count = max_count)]
	return result

def get_all_users(client, q, pp):
	i = 1
	list_users = client.search_users(q=q, page=i, per_page=pp)
	while len(list_users) > 0 and (i-1) * pp <= 1000:
		yield list_users
		try: 
			i = i + 1
			list_users = client.search_users(q="schizophrenic", page=i, per_page=pp, lang="en")
		except:
			break
	yield list_users 

def search_users(client, query):
	res = []
	for sub_list in get_all_users(client, query, 20):
		res = res + sub_list
	return res

if __name__ == "__main__":
	main() 