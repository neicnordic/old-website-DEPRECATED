#!/usr/bin/env python
"""\
Check for inconsistencies and missing info in conference program data.

Exit code == 0 and no output means success.

Exit code == 0 and output on stdout means validation error found.

Exit code != 0 means other error, details/traceback on stderr.
"""
import codecs
import optparse
import os
import sys

import yaml

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
            '-d', '--sitedir', action='store', default=os.path.dirname(os.path.dirname(__file__)),
            help=("Site root directory."))

def usage(message):
    sys.stderr.write(message + "\n")
    sys.stderr.write(Options().get_usage())
    return os.EX_USAGE

class ValidationError(Exception):
    """Raised on finding inconsistent data."""

def error(msg, *args, **kw):
    if args:
        msg %= args
    elif kw:
        msg %= kw
    raise ValidationError(msg)

def _get(datadict, key, default=[]):
    return datadict.get(key, None) or default

datasets = [
    'people',
    'groups',
    ]

def load_dataset(datadir, dataset):
    return yaml.load(open(os.path.join(datadir, dataset + '.yml')))

def load_data(datadir):
    event = dict()
    for dataset in datasets:
        event[dataset] = load_dataset(datadir, dataset)
    return event

### General purpose 

def assert_string_keys(label, datadict):
    for k in datadict.keys():
        if not isinstance(k, str):
            error("%s %r incorrect key type, must be a string.", label, k)

def assert_value_data_types(label, datadict, datatype, *keys):
    if not keys:
        keys = datadict.keys()
    for k in keys:
        value = datadict.get(k, None)
        if value and not isinstance(value, datatype):
            error("%s %s %r must be %s.", label, k, value, datatype)

def assert_item_data_types(label, datalist, datatype):
    for i, item in enumerate(datalist):
        if not isinstance(item, datatype):
            error("%s %s must be %s.", label, i + 1, datatype)

### People

def validate_people(people):
    assert_string_keys('Person', people)
    for id, person in people.items():
        assert_value_data_types('Person %r' % id, person, basestring, 'name', 'role', 'home')
        assert_value_data_types('Person %r' % id, person, str, 'email', 'image', 'country', 'phone')
        if not person.get('name', None):
            error("Person %r has no name.", id)
        assert_item_data_types('Person %r groups' % id, _get(person, 'groups'), str) 

def validate_groups(groups):
    assert_string_keys('Group', groups)
    for id, group in groups.items():
        assert_value_data_types('Group %r' % id, group, basestring, 'name')
    
### Consistency checks

def assert_consistent_person_groups(people, groups):
    known_groups = set(groups)
    for id, person in people.items():
        bad = set(_get(person, 'groups')) - known_groups
        if bad:
            error("Person %r group(s) %r do not exist in the persons register.", id, ', '.join(bad))

### Full integrity check 

def integrity_check(data):
    validate_people(data['people'])
    validate_groups(data['groups'])
    assert_consistent_person_groups(data['people'], data['groups'])
    
def main(argv=None):
    if argv is None:
        argv = sys.argv
    options, args = Options().parse_args(argv[1:])
    if args:
        return usage("This program takes no arguments.")
    data = load_data(os.path.join(options.sitedir, '_data'))
    try:
        integrity_check(data)
    except ValidationError as e:
        print ', '.join(str(arg) for arg in e.args)
    return 0
    
if __name__ == '__main__':
    sys.exit(main())

