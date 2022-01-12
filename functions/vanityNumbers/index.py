import json
import itertools
from nltk.corpus import words

def lambda_handler(event, context):
    # nltk.data.path.append("/var/task/nltk_data")
    setofwords = set(words.words())

    customerPhone = event['Details']['ContactData']['CustomerEndpoint']['Address']
    splitNum = split_number(customerPhone)

    print('entering lambda')
    possibilities = {}
    for split in splitNum:
        splitString = ''.join(split)
        if len(split) >= 3:
            possibilities[splitString] = get_possibilities(split)
    
    vanities = []
    for results in range(0,5):
        result = ''
        for split in splitNum:
            splitString = ''.join(split)
            if len(split) < 3:
                result += splitString
            else:
                result += possibilities[splitString][results]
        vanities.append(result)
    
    print('customer', customerPhone[-10:])
    print('vanities', vanities)

    return {
        'Customer': ' '.join(str(customerPhone[-10:])),
        'VanityNumbers1': ' '.join(vanities[0]),
        'VanityNumbers2': ' '.join(vanities[1]),
        'VanityNumbers3': ' '.join(vanities[2]),
        'VanityNumbers4': ' '.join(vanities[3]),
        'VanityNumbers5': ' '.join(vanities[4])
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

def get_possibilities(number):
    result = []
    endVal = ''
    numCopy = number[:]
    
    originalResult = generate_possibilities(number)
    result.extend(originalResult['words'])
    while len(result) < 5:
        if len(numCopy) <= 2:
            garbage = originalResult['garbage'][5 - len(result)]
            result.append(garbage)
        else:
            possibilities = generate_possibilities(numCopy)['words']
            newPossibilities = [elem + endVal for elem in possibilities]
            result.extend(newPossibilities)
            endVal = numCopy.pop() + endVal
    return result

def generate_possibilities(number):
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

    result = { 'words': [], 'garbage': [] }
    iterList = []
    for n in number:
        iterList.append(vanityMapping[n])
    possibilities = list(itertools.product(*iterList))

    print("iterating through possibilities now")
    for possibility in possibilities:
        word = ''.join(possibility)
        if word in setofwords:
            result['words'].append(word)
        else:
            result['garbage'].append(word)
    print("finished iterating through")

    return result