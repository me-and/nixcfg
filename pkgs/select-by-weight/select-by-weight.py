#!/usr/bin/env python3

import os
from os.path import getsize, join
import random
import pickle
import argparse
import gzip


def get_weights(directory):
    cum_weight = 0
    cum_weights = []
    paths = []
    for root, dirs, files in os.walk(directory):
        for name in files:
            path = join(root, name)
            paths.append(path)
            cum_weight += getsize(path)
            cum_weights.append(cum_weight)
    return paths, cum_weights


def parse_args(args=None):
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-p', '--path')
    group.add_argument('-l', '--load-cache')
    parser.add_argument('-c', '--store-cache')
    parser.add_argument('-n', '--count', type=int, default=1)

    return parser.parse_args(args)


if __name__ == '__main__':
    options = parse_args()

    if options.load_cache is not None:
        with gzip.open(options.load_cache, 'rb') as cache_file:
            paths, cum_weights = pickle.load(cache_file)
    else:
        paths, cum_weights = get_weights(options.path)

    if options.store_cache is not None:
        with gzip.open(options.store_cache, 'wb') as cache_file:
            pickle.dump((paths, cum_weights), cache_file)

    for path in random.choices(paths, cum_weights=cum_weights, k=options.count):
        print(path)
