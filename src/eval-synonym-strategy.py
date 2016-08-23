#!/usr/bin/env python3

import argparse
import json
import re
import gzip

def main():

    parser = argparse.ArgumentParser(description='OBO Syns'
                                                 'Helper utils for OBO Syns',
                                     formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument('-i', '--include', nargs='+', default=[],
                        help='onts to include')
    parser.add_argument('-t', '--tsv', type=str, required=True,
                        help='Input tsv file')
    parser.add_argument('-s', '--strategy', type=str, default='all', required=False,
                        help='Strategy: all/exact')
    parser.add_argument('files',nargs='*')
    args = parser.parse_args()

    strategy = args.strategy
    print("## STRATEGY: "+strategy)
    inclusion_list = list(args.include)

    
    sindex = {}
    for fn in args.files:
        f = open(fn, 'r')
        index_syns(json.load(f), sindex)
        f.close()
    f = open(args.tsv, 'r')
    spans = f.readlines()
    TP = 0
    FP = 0
    FN = 0
    for span in spans:
        span = span.rstrip()
        (id,start,end,text,ont,targetCls,targetLabel) = tuple(span.split("\t"))
        ont = normalize_ont(ont)
        if skip_ont(ont, inclusion_list):
            continue
        ntext = normalize_text(text)
        result = ""
        if ntext not in sindex:
            result = "false_negative"
            FN = FN+1
        else:
            matches = sindex[ntext]
            filtered_matches = []
            has_precise_match = False
            for m in matches:
                if m['ontology'] == ont:
                    scope = m['scope'].lower()
                    if strategy_allows_scope(strategy, scope):
                        filtered_matches.append(m)
                        if scope_is_precise(scope):
                            has_precise_match = True
            if has_precise_match:
                filtered_matches = [m for m in filtered_matches if match_is_precise(m)]
            if len(filtered_matches) == 0:
                result = "false_negative"
                FN = FN+1
            elif len(filtered_matches) == 1:
                m = filtered_matches[0]
                if m['id'] == targetCls:
                    result = "true_positive"
                    TP = TP+1
                else:
                    result = "false_positive"
                    FP = FP+1
            else:
                # if >1 filtered match, we cannot select any one reliably
                result = "false_negative"
                FN = FN+1

            print(result+"\t"+span)
            
    precision = TP / (TP+FP)
    recall = TP / (TP+FN)
    F1 = 2*TP / (2*TP+FP+FN)
    print("## DONE")
    print("### Strategy:"+strategy)
    print("### Onts:"+str(inclusion_list))
    print("### TP: "+str(TP))
    print("### FP: "+str(FP))
    print("### FN: "+str(FN))
    print("### Precision: "+str(precision))
    print("### Recall: "+str(recall))
    print("### F1: "+str(F1))
    
def strategy_allows_scope(strategy, scope):
    if (strategy == 'all'):
        return True
    elif (strategy == 'exact'):
        return scope_is_precise(scope)
    elif (strategy == 'exrel'):
        return scope_is_precise(scope) or scope.lower() == 'related'
    else:
        print("## NO SUCH STRATEGY:" + strategy)
        return False

def match_is_precise(m):
    return scope_is_precise(m['scope'].lower())

def scope_is_precise(s):
    return s == 'name' or s == 'exact'

def index_syns(smap, sindex):
    skipped = []
    for (id,objs) in smap.items():
        for obj in objs:
            nsyn = normalize_text(obj['synonym'])
            if nsyn not in sindex:
                sindex[nsyn] = []
            obj['id'] = id
            toks = id.split(":")
            if len(toks) == 2:
                (idspace,localid) = tuple(toks)
                obj['ontology'] = idspace.lower()
                sindex[nsyn].append(obj)
            else:
                skipped.append(id)
    print("## SKIPPED: "+str(skipped))

def normalize_ont(ont):
    ont = ont.lower()
    if ont == 'go_cc':
        return 'go'
    if ont == 'go_bpmf':
        return 'go'
    return ont

def normalize_text(text):
    ## TODO
    pattern = re.compile(r's$')
    text = text.lower().replace("'","")
    return pattern.sub(r'', text)

def skip_ont(ont, inclusion_list):
    if len(inclusion_list) == 0:
        return False;
    return ont not in inclusion_list

    
if __name__ == "__main__":
    main()    
