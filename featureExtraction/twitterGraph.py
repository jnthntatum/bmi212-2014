#/usr/bin/python3
"""
twitterGraph.py
load and analyse the twitter graph

Too slow at the moment -- the rate limiting makes it take hours to run anything...
Jon Tatum 
jdtatum@cs.stanford.edu
"""

from collections import deque
import twitterMine
from twitterMine import get_followers, get_following, get_description, throttle_fn
import sys
import json
import utils
import twython
import os

def bfs_get_successors ( client, node, accumulator ):
	tid = str(node[0])
	depth = node[1]
	description = None
	if tid not in accumulator:
		description = None
		try: 
			description = throttle_fn( client, get_description, tid )
		except twython.TwythonRateLimitError as trle:
			debug.log( "Error rate limit.")
			raise trle
		except twython.TwythonError as te:
			debug.log( "Error: %s" % str(te) )
			# likely a private user so just mark that
			description = {"private_user": True, "following_ids": [], "leaf": True}
		
		accumulator[tid] = description 
	else:
		description = accumulator[tid]
	
	frontier = []
	if depth != 0 and 'following_ids' not in description: 

		following = throttle_fn( client, get_following, tid)
		
		utils.debug("loaded edges for %s" % tid)
		
		sing = set(following)
		
		description['following_ids'] = following
		description['leaf'] = False
		frontier = [ (x, depth - 1) for x in sing ]
	elif depth == 0 and 'leaf' not in description:
		description['leaf'] = True

	return frontier



def bfs( client, starting_nodes, depth = 2, accumulator = {}, ):
	"""
	load local neighborhoods of a set of nodes. Depending on the size 
	of the neighborhood, this can be an expensive task (many api calls).
	"""
	bfs_queue = [ (node, depth) for node in starting_nodes ]
	bfs_queue = deque(bfs_queue)
	while len(bfs_queue) > 0:
		node = bfs_queue.popleft()
		
		bfs_queue.extend( bfs_get_successors( client, node, accumulator ) )

	return accumulator  


def to_tgf( fname, descriptions ):
	"""
	convert to graph format for visualization
	"""
	i = 1
	small_ids = {}
	def get_small_id( tid ):
		sid = None
		if tid in small_ids:
			sid = small_ids[tid]
		else:
			sid = small_ids[tid] = i		
			i += 1
		return sid
	
	with open(fname, 'w+') as fhandle:

		for tid in descriptions:
			fhandle.write("%d %s\n" % (get_small_id(tid), tid))

		fhandle.write("#\n")
		
		edges = set()

		for tid, description in descriptions.items():
			if description['leaf']:
				continue; 
			sid = get_small_id(tid)
			for fid in description['following_ids']:
				sid2 = get_small_id(fid)
				e = (sid, sid2)
				if e in edges:
					continue
				edges.add(e)
				fhandle.write("%d %d\n" % (sid, sid2))
		fhandle.close()
	
def download_neighborhood( id_file, out_file, bfs_depth ):
	print( " building neighborhood network " )

	ids = None
	with open(id_file, 'r') as id_f:
		ids = [ x.strip() for x in id_f if len(x.strip()) > 0 ] 
	
	if ids is None or len(ids) == 0:
		print ("could not read %s" % id_file)
		sys.exit(1)
	
	print( "querying twitter for user descriptions. This may take a while." )
	
	twitter_client = twitterMine.setup() 
	old_results = {}
	if os.path.isfile(out_file):
		with open(out_file, r) as out_f:
			old_results = json.load(out_f)
	results = bfs( twitter_client, ids, bfs_depth, old_results ); 

	print( "done! writing results to %s" % out_file )
	
	with open( out_file ) as out_f:
		json.dump( results, out_f )

	print( "success! exiting" )


USAGE = """
usage:
	python3 twitterGraph.py <seed_id_file> <ouput_file> [<bfs-depth>]

	seed_id_file: 	a list of ids as the starting frontier of the breadth first search.
				one id per line, lines beginning with '#' ignored
	output_file: 	file to store the result of the query
	bfs-depth: 		the number of hops to consider for bfs
"""

if __name__ == "__main__":
	if len(sys.argv) < 3:
		print("Error not enough arguments")
		print(USAGE)
		sys.exit(1)
	
	id_file 	= sys.argv[1]
	out_file 	= sys.argv[2]
	bfs_depth 	= 2

	download_neighborhood( id_file, out_file, bfs_depth )

	

		