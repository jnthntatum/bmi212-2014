#!/usr/bin/python
"""
Run through cache of tweets and extract features for classification task. 

Jon Tatum jdtatum@cs.stanford
Emily Doughty 
"""
import config
import utils
import re
import nltk
from nltk.stem.wordnet import WordNetLemmatizer

from collections import defaultdict
import dbUtils
import json
import csv
import time
import datetime

import numpy as np

EMOTICON_FILE = "./smiley.txt"
SCHIZO_WORDS_FILE = "./schizophrenia_words.txt"

defaultdict(lambda: 0)

# keep information around so we don't have to load / compile every
# tweet
class TweetProcessor(object):
  def __init__(self):
    self.drugs = utils.load_drug_file()
    self.emoticons_to_type, self.type_to_emoticons = load_emoticon_file()
    self.schizo_words = load_schizo_file()
    self.porter = nltk.PorterStemmer()
    self.lmtzr = WordNetLemmatizer()

    self.emoticon_regexes = emr = {}
    for etype, emotes in self.type_to_emoticons.items():
      emotes_str = "|".join([re.escape(e) for e in emotes])
      regex = re.compile( "({0})".format(emotes_str))
      emr[etype] = regex


  def process_tweet(self, text, result = defaultdict(lambda: 0)):

    tokens = nltk.wordpunct_tokenize(text)
    
    #making flags because we only want to count once if we see it in a tweet
    emoticon_flag = 0
    schizo_flag = 0
    drug_flag = 0

    etype_flags = defaultdict(lambda: 0);

    for etype, regex in self.emoticon_regexes.items():
      if regex.search(text) is not None:
        etype_flags[etype] = 1
        emoticon_flag = 1

    for token in tokens:
      lemma =  self.lmtzr.lemmatize(token)
      if lemma in self.schizo_words: 
        schizo_flag = 1
      if lemma in self.drugs: 
        drug_flag = 1

    result["schizo"] += schizo_flag
    result["drug"] +=  drug_flag
    result["emoticon"] += emoticon_flag
    for etype in self.type_to_emoticons:
      result[etype] += etype_flags[etype]

    return result

def load_emoticon_file():
  smiley_to_type = {}
  type_to_smiley = defaultdict(list)
  
  with open(EMOTICON_FILE, "r") as f_in:
    for line in f_in:
      elts = re.split("\\s+", line.rstrip())
      emote_type = elts[0]
      elts.pop(0)
      for emote in elts:
        smiley_to_type[emote] = emote_type
        type_to_smiley[emote_type].append(emote)
  return (smiley_to_type, type_to_smiley) 

def load_schizo_file():
  result = {}

  with open(SCHIZO_WORDS_FILE, 'r') as f_handle:
    for word in f_handle:
      word = word.strip(); 
      result[word] = 1

  return result

def get_timestamps(datetimes):
  dt_sec = [t.timestamp() for t in datetimes]
  
  deltas = np.array([dt_sec[i-1] - dt_sec[i] for i in range(1, len(dt_sec))])
  deltas.sort()
  
  to_sec = lambda x: x.hour * 60 * 60 + x.minute * 60 + x.second + 10**-6 * x.microsecond
  times = np.array([to_sec(dt.time()) for dt in datetimes])
  times.sort()

  return dt_sec, times, deltas

def add_time_model(tweets, feature_map):
  datetimes = [t['tweet_time'] for t in tweets]
  dt_sec, times, deltas = get_timestamps(datetimes)
  
  if len(deltas) < 10: 
    return result;
  
  feature_map['delay.10th'] = np.percentile(deltas, 10)
  feature_map['delay.25th'] = np.percentile(deltas, 25)
  feature_map['delay.50th'] = np.percentile(deltas, 50)
  feature_map['delay.75th'] = np.percentile(deltas, 75)
  feature_map['delay.90th'] = np.percentile(deltas, 90)

  feature_map['delay.mean'] = np.mean(deltas)
  feature_map['delay.sd']   = np.std(deltas)

  feature_map['time.10th']  = np.percentile(times, 10)
  feature_map['time.25th']  = np.percentile(times, 25)
  feature_map['time.50th']  = np.percentile(times, 50)
  feature_map['time.75th']  = np.percentile(times, 75)
  feature_map['time.90th']  = np.percentile(times, 90)
  
  sec_per_hour = 60 * 60 

  morning = (times >= (5 * sec_per_hour)) * (times < (9 * sec_per_hour))   
  day     = (times >= (9 * sec_per_hour)) * (times < (18 * sec_per_hour))
  evening = (times >= (18 * sec_per_hour)) * (times < (24 * sec_per_hour))
  night   = (times >= (0 * sec_per_hour)) * (times < (5 * sec_per_hour))
  
  feature_map['time.morning'] = float(np.sum(morning)) / float(len(times))
  feature_map['time.day'] = float(np.sum(day)) / float(len(times))
  feature_map['time.evening'] = float(np.sum(evening)) / float(len(times))
  feature_map['time.night'] = float(np.sum(night)) / float(len(times))

  return feature_map

def write_csv (fname, results):
  fields = list(results[0].keys())
  fields.sort()
  with open(fname, "w+") as f_out:
    writer = csv.writer(f_out, delimiter="\t")
    writer.writerow(fields)
    for row in results:
      row_elems = [row[k] if k in row else 0 for k in fields]
      writer.writerow(row_elems)


if __name__ == "__main__":
  processor = TweetProcessor()
  results = []
  with dbUtils.setup_mysql_cxn() as cxn:
    curs = cxn.cursor();
    curs.execute(dbUtils.GET_USERS_W_COHORT)
    users = dbUtils.get_named_rows(curs)
    for user in users:
      
      curs.execute(dbUtils.GET_TWEETS_TEMPL % user['twitter_user_id'])
      tweets = dbUtils.get_named_rows(curs)
      result = defaultdict(lambda: 0)
      for tweet in tweets:
        result = processor.process_tweet(tweet['tweet_text'], result)
      ntweets = len(tweets)
      if ntweets > 0:
        for k, v in result.items():
          result[k] = float(v) / float(ntweets)
      result = add_time_model(tweets, result)
      
      if user['utc_offset_sec'] is None:
        result['time.offsetted'] = False
      else:
        result['time.offsetted'] = True

      result['user.id'] = user['twitter_user_id']

      result['in.degree'] = user['followers_count']
      result['out.degree'] = user['following_count']

      result['num.tweets'] = ntweets
      result['total.tweets'] = user['statuses_count']
      result['label'] = user['cohort_id']
      result['cohort_name'] = user['cohort_name']
      results.append(result)
  with open('features.json', 'w+') as f_handle:
    json.dump(results, f_handle)
  write_csv('features.csv', results) 