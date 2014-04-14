#!/usr/bin/python3
#twitterMine.py

import utils
import twython

def main():
	# should change these to use a dynamically loaded file
	drugs = utils.load_drug_file()
	creds = utils.load_credentials_file()
	api_client = twython.Twython(*creds)

	drugs_to_search = [ '"' + el + '"' if el.find(' ') >= 0 else el for el in drugs['clozapine'] ]
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

	
def setup(file = utils.DEFAULT_CRED):
	creds = utils.load_credentials_file()
	api_client = twython.Twython(*creds)
	return api_client

def get_followers_and_following(client, uid):
	a = client.get_friends_ids(user_id = uid)['ids']
	b = client.get_followers_ids(user_id = uid)['ids']
	return set(a) & set(b)

def get_timeline(client, uid):
	blob = client.get_user_timeline(user_id = uid)
	return blob

if __name__ == "__main__":
	main() 