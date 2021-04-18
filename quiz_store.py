# -*- coding: utf-8 -*-

# Copyright (c) 2020 shmilee

import re
import sys
import unicodedata

PAT_MAIN = re.compile(r'''
    \s*[(（]{1}(?P<answer>(?:[ABCDabcd]{1,4}|[√×]{1}))[)）]{1} # answer
    \s*(?P<number>\d+)\s*\.\s* # number
    (?P<content>.*) # question
    \s*[\n]{0,1}
    ''', re.VERBOSE)

PAT_MAIN = re.compile(r'''
    \s*(?P<number>\d+)\s*\.\s* # number
    (?P<content>.*[(（]{1}\s*(?P<answer>(?:[ABCDabcd]{1,4}|[√×]{1}))\s*[)）]{1}.*) # question     # answer
    \s*[\n]{0,1}
    ''', re.VERBOSE)

PAT_MAIN = re.compile(r'''
    \s*(?P<number>\d+)\s*[\.、]\s* # number
    (?P<content>.* # question
    [\(（]{1}\s*)
    (?P<answer>[ABCDabcd]{1,4}) # answer
    (?P<content_tail>\s*[)）]{1}.*) # question
    \s*[\n]{0,1}
    ''', re.VERBOSE)

PAT_MAIN2 = re.compile(r'''
    \s*(?P<number>\d+)\s*[\.、]\s* # number
    (?P<content>.* # question
    [\(（]{1}\s*)
    (?P<answer>[对错]{1}) # answer
    (，(?P<analysis>.*)){0,1} # answer
    (?P<content_tail>\s*[)）]{1}.*) # question
    \s*[\n]{0,1}
    ''', re.VERBOSE)

PAT_OPTION = re.compile(r'''
    (\s*(?P<opt>[ABCDEabcde]){1}\.\s*
    (?P<opt_content>.*)){1,5}
    \s*[\n]{0,1}
    ''', re.VERBOSE)

PAT_OPTION = re.compile(r'''
    (\s*[Aa]{1}\s*[\.、．]\s*
    (?P<optA>[^BCDE]*)){0,1}
    (\s*[Bb]{1}\s*[\.、．]\s*
    (?P<optB>[^CDE]*)){0,1}
    (\s*[Cc]{1}\s*[\.、．]\s*
    (?P<optC>[^DE]*)){0,1}
    (\s*[Dd]{1}\s*[\.、．]\s*
    (?P<optD>[^E]*)){0,1}
    (\s*[Ee]{1}\s*[\.、．]\s* # optional E
    (?P<optE>.*)){0,1}
    \s*[\n]{0,1}
    ''', re.VERBOSE)


class Question(object):
    def __init__(self, content, answer, **kwargs):
        self.content = unicodedata.normalize('NFKC', content).strip()
        c_tail = kwargs.get('content_tail', '')
        if c_tail:
            c_tail = unicodedata.normalize('NFKC', c_tail).strip()
            self.content = self.content + ' ' + c_tail
        self.answer = answer.strip()
        if self.answer in ('√', '×', '对', '错'):
            self.qtype = 'TorF'
        elif re.match(r'[ABCDabcd]{1,4}', self.answer):
            self.qtype = 'Choice'
        else:
            self.qtype = None
        com_attrs, opt_attrs = ['number', 'analysis', 'level'], []
        if self.qtype == 'Choice':
            opt_attrs = ['optA', 'optB', 'optC', 'optD', 'optE']
        for attr in com_attrs+ opt_attrs:
            val = kwargs.get(attr, None)
            if val is not None:
                if attr not in ['number', 'level']:
                    val = unicodedata.normalize('NFKC', val).strip()
                else:
                    val = val.strip()
            setattr(self, attr, val)

    def show(self, fmt='cx1'):
        if fmt == 'cx1': # chaoxing 智能
            num = '1' if self.number is  None else self.number
            out = '%s、%s\n' % (num, self.content)
            if self.qtype == 'Choice':
                for attr in ('optA', 'optB', 'optC', 'optD', 'optE'):
                    opt = getattr(self, attr)
                    if opt is not None:
                        out += '%s.%s\n' %(attr[3], opt)
            out += '答案：%s\n' % self.answer
            if self.analysis is not None:
                out += '答案解析：%s\n' % self.analysis
            if self.level is not None:
                out += '难易度：%s\n' % self.level
            print(out)
        elif fmt == '':
            pass

def get_objs_from_txt(path):
    txt = open(path, 'r')
    data = txt.readlines()
    i = 0
    length = len(data)
    results = []
    while i < length:
        m = PAT_MAIN.match(data[i])
        if not m:
            m = PAT_MAIN2.match(data[i])
        if m:
            kwargs = m.groupdict()
            answer = kwargs.get('answer', None)
            if answer in ('√', '×', '对', '错'):
                results.append(Question(**kwargs))
            elif re.match(r'[ABCDEabcde]{1,5}', answer):
                ii = i
                for j in range(1,6):
                    m2 = PAT_OPTION.match(data[ii+j])
                    opts = {}
                    for k, v in m2.groupdict().items():
                        if v is not None:
                            opts[k] = v
                    if opts:
                        i = i + 1
                        kwargs.update(opts)
                    else:
                        #print('WARN: line %d lost options!' % (ii+j))
                        break
                results.append(Question(**kwargs))
        i = i + 1
    return results

def test_main(path):
    results = get_objs_from_txt(path)
    for q in results:
        q.show()

try:
    path = sys.argv[1]
except IndexError as e:
    path = './zfy/01test.txt'
    path = './zfy/党史知识竞赛题库.txt'

test_main(path)


'''
test=docx.Document('./2020汽车修理类 学测考试专业理论试题 01.docx')
p=test.paragraphs[1]
PAT_MAIN.match(p.text)
PAT_OPTION.match(p.text)
'''
