#!/usr/bin/python3

# utils.py
# helper functions that are useful in different modules (and probably ugly)

from collections import namedtuple
import urllib

SCHIZO_DRUGS = './schizo_drugs.dat'
DEFAULT_CRED = './jtatum.cred'

def url_encode( url ):
	return urllib.parse.quote( url )


def load_drug_file( fname = SCHIZO_DRUGS ):
	result = {}
	with open(fname, 'r') as file:
		for line in file:
			if line.startswith('#'):
				continue 
			drugs = line.strip().split(',');
			result[drugs[0]] = drugs
	return result


OAuthCredentials = namedtuple('credentials', ('client_key', 'client_secret', 'access_token', 'access_token_secret'))

def load_credentials_file ( fname = DEFAULT_CRED ):
	result = None	
	with open(fname, 'r') as f:
		row = f.readline().split(',')
		result = OAuthCredentials(*row)
	return result

