#!/usr/bin/python
"""\
Check for missing conference data, sorted by person responsible.
"""
import codecs
import optparse
import os
import re
import sys

import yaml

from validate import (
    _get,
    error,
    integrity_check,
    load_data,
    usage,
    )

# Ugly hack: only ever write utf-8 to stdout, especially if it is a pipe with no encoding set.
# Uncomment this if you get unicode errors on print.
# Better solution: port to python3.
#sys.stdout = codecs.getwriter('utf-8')(sys.stdout)

class Options(optparse.OptionParser):
    
    def __init__(self):
        global __doc__
        optparse.OptionParser.__init__(
            self, usage="%prog [options]",
            description=__doc__)
        self.add_option(
            '-d', '--sitedir', action='store', default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            help=("Site root directory."))
        self.add_option(
            '-i', '--person-id', action='store', default=None,
            help=("Nag person with matching id (regex, caseless)."))
        self.add_option(
            '-n', '--name', action='store', default=None,
            help=("Nag person with matching name (regex, caseless)."))
        self.add_option(
            '-t', '--test', action='store', default='all',
            help=("Comma separated list of tests to run (default: all), or prepend a - to skip that test."))
        self.add_option(
            '-l', '--list-tests', action='store_true', default=False,
            help=("List available tests."))

def complain_if_missing(complaints, path, blame, obj_id, obj, require_truthy, **requirements):
    for key, complaint in requirements.items():
        if complaint is None:
            complaint = "Missing {key} in {path}[{obj_id!r}]"
            if obj.get('title', None):
                complaint += " {obj[title]!r}"
            complaint += '.'
        ok = obj.get(key, None)
        if ok is None or (require_truthy and not ok):
            b = (blame or '').format(obj_id=obj_id, obj=obj, key=key, path=path)
            c = complaint.format(obj_id=obj_id, obj=obj, key=key, path=path)
            complaints.setdefault(b or None, []).append(c)

def test_missing(event, path, blame, specs, require_truthy=False):
    complaints = dict()
    if isinstance(specs, str):
        specs = {specs: None}
    elif isinstance(specs, list):
        specs = dict.fromkeys(specs, None)
    for id, p in event[path].items():
        complain_if_missing(complaints, path, blame, id, p, require_truthy, **specs)
    return complaints

def test_talk_missing(event, specs, require_truthy=False):
    complaints = dict()
    if isinstance(specs, str):
        specs = {specs: None}
    elif isinstance(specs, list):
        specs = dict.fromkeys(specs, None)
    for session_id, session in event['sessions'].items():
        for i, talk in enumerate(_get(session, 'talks')):
            path = "session[%r] talk %i " % (session_id, i + 1, )
            talk_id = talk.get('id', talk.get('speaker'))
            complain_if_missing(complaints, path, session.get('chair', None), talk_id, talk, require_truthy, **specs)
    return complaints

TESTS = dict(
    # People
    org=dict(description="Missing email, home organization, country or NeIC role.",
        callback=test_missing, kw=dict(path='people', blame='{obj_id}', specs=dict(
            email="Missing email address.",
            home="Missing home organization name.",
            country="Missing country.",
            role="Missing role in NeIC.",
            ))),
    image=dict(description="Missing person image.",
        callback=test_missing, args=('people', '{obj_id}', dict(
            image="Missing image.",
            ))),
    phone=dict(description="Missing person phone number.",
        callback=test_missing, args=('people', '{obj_id}', dict(
            phone="Missing phone number.",
            ))),
    groups=dict(description="Missing groups.",
        callback=test_missing, args=('people', '{obj_id}', dict(
            groups="Missing groups.",
            ))),
    )

_PERSONAL_TESTS = ['org', 'image', 'phone', 'groups']

METATESTS = dict(
    all=dict(description="Run all tests (this is the default).", which=None),
    personal=dict(description="Personal attacks; short for %s." % ','.join(sorted(_PERSONAL_TESTS)), 
        tests=_PERSONAL_TESTS),
    )

def list_tests(tests, metatests):
    items = sorted(metatests.items()) + sorted(tests.items())
    width = max(len(it[0]) for it in items)
    print '\n'.join("%-*s %s" % (width, it[0], it[1]['description']) for it in items)

def get_tests(testspec):
    tests = set(testspec.split(','))
    if 'all' in tests:
        tests |= set(TESTS.keys())
        tests.remove('all')
    for metatest in (tests & set(METATESTS.keys())):
        tests |= set(METATESTS[metatest]['tests'])
        tests.remove(metatest)
    for subtract in [t for t in tests if t.startswith('-')]:
        tests.remove(subtract)
        test = subtract[1:]
        if test in METATESTS:
            tests -= set(METATESTS[test]['tests'])
        else:
            tests.remove(test)
    bad = tests - set(TESTS.keys())
    if bad:
        error("Unknown test(s): %r", ','.join(bad))
    return tests

def search_person_ids(person_regex, event, search_names=False):
    person_ids = []
    r = re.compile(person_regex, re.I)
    for person_id, person in event['people'].items():
        to_search = person_id
        if search_names:
            to_search = person['name']
        if r.search(to_search):
            person_ids.append(person_id)
    if not person_ids:
        label = "person names" if search_names else "person_ids"
        error("No %s matching %r.", label, person_regex)
    return set(person_ids)

def get_person_ids(options, event):
    p1 = p2 = None
    if options.person_id is not None:
        p1 = search_person_ids(options.person_id, event)
    if options.name is not None:
        p2 = search_person_ids(options.name, event, search_names=True)
    if p1 and p2: 
        person_ids = p1 & p2
        if not person_ids:
            error("No persons matching id %r and name %r", options.person_id, options.name)
        return person_ids
    if p2 is None:
        return p1
    return p2

def get_complaints(event, tests, person_id_restriction=None):
    complaints = dict()
    for test in tests:
        cb = TESTS[test]['callback']
        args = TESTS[test].get('args', [])
        kw = TESTS[test].get('kw', {})
        for person_id, new_complaints in cb(event, *args, **kw).items():
            if person_id_restriction:
                if not person_id or person_id not in person_id_restriction:
                    continue 
            complaints.setdefault(person_id, []).extend(new_complaints)
    return complaints

def print_complaints(event, complaints):
    complaints = dict(complaints)
    general = sorted(complaints.pop(None, []))
    if general:
        print "GENERAL:"
        print '    * ' + '\n    * '.join(general)
        print
    for person_id, nags in complaints.items():
        name = event['people'][person_id]['name']
        email = event['people'][person_id].get('email', None)
        print "%s: %s%s" % (person_id, name, (' <%s>' % email) if email else '')
        print '    * ' + '\n    * '.join(sorted(nags))
        print
         

def main(argv=None):
    if argv is None:
        argv = sys.argv
    options, args = Options().parse_args(argv[1:])
    if args:
        return usage("This program takes no arguments.")
    if options.list_tests:
        list_tests(TESTS, METATESTS) 
        return 0
    event = load_data(os.path.join(options.sitedir, '_data'))
    integrity_check(event)
    person_ids = get_person_ids(options, event)
    tests = get_tests(options.test)
    complaints = get_complaints(event, tests, person_ids)
    print_complaints(event, complaints)
    return 0
    
if __name__ == '__main__':
    sys.exit(main())

