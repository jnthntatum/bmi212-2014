#!/usr/bin/python3

# utils.py
# helper functions that are useful in different modules (and probably ugly)
# Jon Tatum jdtatum@cs.stanford.edu

from collections import namedtuple, defaultdict
import config
import sys
import urllib

version = sys.version_info

if ( version[0] >= 3 and version[1] >= 2 ):
	def url_encode( url ):
		return urllib.parse.quote( url )
elif ( version[0] >= 2 and version[1] >= 6 ):
	def url_encode( url ):
		return urllib.quote(url)
else:
	print ("Error: unsupported version. use python > 2.6")

DEBUG = True

class Counter(defaultdict):
	def __init__(self):
		super(Counter, self).__init__(lambda: 0.0)
	def increment(self, key):
		self[key] = self[key] + 1.0


def debug( message ):
	if ( DEBUG ): 
		sys.stderr.write("%s\n" % message) 

def load_drug_file( fname = config.SCHIZO_DRUGS ):
	result = {}
	with open(fname, 'r') as file:
		for line in file:
			if line.startswith('#'):
				continue 
			drugs = line.strip().split(",");
			drugs = [x.strip() for x in drugs]
			for drug in drugs:
				result[drug] = drugs[0]
	return result


OAuthCredentials = namedtuple('credentials', ('client_key', 'client_secret', 'access_token', 'access_token_secret'))

def load_credentials_file ( fname = config.DEFAULT_CRED ):
	result = None	
	with open(fname, 'r') as f:
		row = f.readline().split(',')
		result = OAuthCredentials(*row)
	return result



