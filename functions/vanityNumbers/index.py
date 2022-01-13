import json
import itertools
import random
import logging
import os
import boto3
from nltk.corpus import brown

setofwords = set([word.upper() for word in brown.words()])
logging.getLogger().setLevel(logging.INFO)

def lambda_handler(event, context):
    dynamodb = boto3.client('dynamodb')

    customerPhone = event['Details']['ContactData']['CustomerEndpoint']['Address']
    splitNum = split_number(customerPhone)

    possibilities = {}
    # set up the sections to receive the vanity portion
    for split in splitNum:
        splitString = ''.join(split)
        if len(split) >= 3:
            possibilities[splitString] = get_possibilities(split, 5, 3)
    
    # for number of desired vanities, create a vanity print
    vanities = []
    for results in range(0,5):
        result = ''

        for split in splitNum:
            splitString = ' '.join(split)
            if len(split) < 3:
                result += splitString + ' '
            else:
                result += possibilities[splitString.replace(' ','')][results] + ' '
        vanities.append(result.strip())
    
    logging.info('customer %s', customerPhone[-10:])
    logging.info('vanities %s', vanities)

    dynamodb.put_item(TableName=os.environ['DB_TABLE'], Item={
        'callerPhone': {'S': customerPhone[-10:] },
        'vanityNumbers': {'L': [{ 'S': vanity.replace(' ', '') } for vanity in vanities] }
    })

    return {
        'Customer': ' '.join(str(customerPhone[-10:])),
        'VanityNumbers1': vanities[0],
        'VanityNumbers2': vanities[1],
        'VanityNumbers3': vanities[2],
        'VanityNumbers4': vanities[3],
        'VanityNumbers5': vanities[4]
    }

def split_number(number):
    number = number[-10:]
    split = []
    currWord = []
    for (index, n) in enumerate(number):
        if n == '1' or n == '0':
            if len(currWord) > 0:
                split.append(currWord)
            split.append([n])
            currWord = []
        else:
            currWord.append(n)

        if index == len(number) - 1:
            split.append(currWord)
    return split

def get_possibilities(number, desired, minText):
    possibilities = []
    endVal = ''
    # creating a copy of the number to not alter it
    numCopy = number[:]

    # generate original
    originalPossibilities = generate_possibilities(number, True)
    possibilities.extend(originalPossibilities['words'])

    while len(possibilities) < desired:
        # too small of text to find words, choose from garbage
        if len(numCopy) <= minText:
            possibilities.append(' '.join(random.choice(originalPossibilities['garbage'])))
        else:
            # remove the last digit and keep track of it
            # remove the last digit for all the possibilities too
            endVal = numCopy.pop() + endVal
            newPossibilities = generate_possibilities(numCopy)['words']
            possibilities.extend([elem + endVal for elem in newPossibilities])

    return possibilities

def generate_possibilities(number, saveGarbage = False):
    vanityMapping = {
        '2': ['A','B','C'],
        '3': ['D','E','F'],
        '4': ['G','H','I'],
        '5': ['J','K','L'],
        '6': ['M','N','O'],
        '7': ['P','Q','R','S'],
        '8': ['T','U','V'],
        '9': ['W','X','Y','Z']
    }

    iterList = []
    # generate all possible combinations
    for n in number:
        iterList.append(vanityMapping[n])
    possibilities = list(itertools.product(*iterList))

    return gather_valid([''.join(elem) for elem in possibilities], saveGarbage)

def gather_valid (possibilities, saveGarbage = False):
    result = {
        'words': [],
        'garbage': []
    }

    for word in possibilities:
        if word in setofwords:
            result['words'].append(word)
        if word not in setofwords and saveGarbage:
            result['garbage'].append(word)

    return result