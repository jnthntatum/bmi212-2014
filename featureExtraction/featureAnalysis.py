#!/usr/bin/python3
# featureAnalysis.py
# generates easily consumable files to generate a few plots of 
# control versus cohort
# Jon Tatum
# jdtatum@cs.stanford


import dbUtils
import utils
import processTweets
import numpy as np



SELECT_CONTROL_TWEETS = \
"""SELECT * FROM tusers AS user  
	JOIN tweets as tweet 
		ON user.twitter_user_id = tweet.twitter_user_id
	WHERE user.cohort_id IN (6)
	ORDER BY tweet.twitter_user_id, tweet.tweet_time DESC;
"""
SELECT_COHORT_TWEETS = \
"""SELECT * FROM tusers AS user
	JOIN tweets as tweet 
		ON user.twitter_user_id = tweet.twitter_user_id
	WHERE user.cohort_id IN (1, 4)
	ORDER BY tweet.twitter_user_id, tweet.tweet_time DESC;
"""

def make_cdfs( fname , tweets ):
	datetimes = [t['tweet_time'] for t in tweets]
	dt_sec, times, deltas = processTweets.get_timestamps(datetimes)
	np.savetxt(fname + "_ts.txt", dt_sec)
	np.savetxt(fname + "_tod.txt", times)
	np.savetxt(fname + "_delta.txt", deltas)


def main():
	controlTweets = None
	cohortTweets = None
	with dbUtils.setup_mysql_cxn() as cxn:
		curs = cxn.cursor()
		curs.execute(SELECT_CONTROL_TWEETS)
		controlTweets = dbUtils.get_named_rows(curs)
		curs.execute(SELECT_COHORT_TWEETS)
		cohortTweets = dbUtils.get_named_rows(curs) 
	make_cdfs("control", controlTweets)
	make_cdfs("cohort", cohortTweets)
if __name__ == "__main__":
	main()
	pass