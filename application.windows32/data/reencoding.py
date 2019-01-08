# -*- coding: utf-8 -*-

import os
import codecs
import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Reencodes Chinese text in '\
                                                 'the csv files within the '\
                                                 'folder given, from 京剧 '\
                                                 'to "\u4eac\u5267"')
    parser.add_argument('folder', help='Path to the folder containing the '\
                                       'the csv files to reencode')

    args = parser.parse_args()
    
    folder = args.folder
    
    allFiles = os.listdir(folder)
    
    csvFiles = []
    
    print('Found these files:')
    
    for f in allFiles:
        if f[-3:] == 'csv':
            csvFiles.append(folder+'\\'+f)
            print('\t'+f)
    print()
    
    for csvFile in csvFiles:
        with open(csvFile, 'r', encoding='utf-8') as f:
            data = f.readlines()
        print('Reencoding', csvFile)
        newFile = csvFile[:-4]+'_encoded.csv'
        lines = ''
        for line in data:
            values = line.rstrip().split(',')
            newLabel = codecs.decode(values[0].encode('unicode-escape'))
            newLine = newLabel
            for value in range(1, len(values)):
                newLine += ','+str(value)
            newLine += '\n'
            lines += newLine
        with open(newFile, 'w') as f:
            f.write(lines)