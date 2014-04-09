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
	results = api_client.search( q = query, count = 60)

	for result in results['statuses']:
		print (result['text']) 
	

if __name__ == "__main__":
	main() 