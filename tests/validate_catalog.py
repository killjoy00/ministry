#!/usr/bin/env python3
"""Standard-library design-time checks for the authored GDScript event catalog.

This validates rule data and approximates the full-run balance before engine CI
is available; it is NOT a substitute for running tests/smoke.gd in Godot.
"""
import ast
import pathlib
import random
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parents[1]
FILE = ROOT / 'scripts/scenarios/fowl_election.gd'


def parse_rules():
    events = []
    for line in FILE.read_text().splitlines():
        if 'r.append(_event(' not in line:
            continue
        contents = line.split('r.append(_event(', 1)[1].rsplit('))', 1)[0]
        parts = ast.literal_eval('(' + contents + ')')
        id_, title, text, chance, reqall, reqany, output, support, location, *alt = parts
        events.append(dict(id=id_, title=title, text=text, chance=chance,
                           all=reqall, any=reqany, facts=output, support=support,
                           place=location, alt=alt))
    return events


def validate(events):
    assert len(events) >= 25, 'need sufficiently rich causal graph'
    ids = [e['id'] for e in events]
    assert len(ids) == len(set(ids)), 'duplicate event ids'
    defined_facts = set().union(*(set(e['facts']) | (set(e['alt'][0]) if e['alt'] else set()) for e in events))
    for e in events:
        assert e['title'] and e['text'] and e['place'], f"missing authored prose {e['id']}"
        assert 0 < e['chance'] < 1, f"invalid probability {e['id']}"
        assert e['support'] >= 0, f"negative support {e['id']}"
        assert not (set(e['all']) & set(e['any'])), f"redundant conditions {e['id']}"
        for requirement in e['all'] + e['any']:
            assert requirement in defined_facts, f"unreachable fact '{requirement}' in {e['id']}"
    assert {'goose_candidate', 'goose_eligible', 'goose_petition'}.issubset(defined_facts)
    return defined_facts


def simulate(events, seed, strategy=False):
    """Approximation of two spontaneous incidents + at most one player nudge/day."""
    rng = random.Random(seed)
    facts, fired = set(), set()
    support, max_daily, total = 0, 0, 0

    def eligible(e):
        return (e['id'] not in fired and set(e['all']).issubset(facts)
                and (not e['any'] or set(e['any']).intersection(facts)))

    for day in range(1, 8):
        choices = [e for e in events if eligible(e)]
        target = None
        if strategy and choices:
            def utility(e):
                # A plausible player tries to unlock a candidacy, then gather votes.
                priorities = {'goose_eligible': 5, 'goose_petition': 6,
                              'goose_candidate': 9, 'goose_photo': 3,
                              'goose_headline': 4, 'goose_viral': 3}
                return priorities.get(e['facts'][0] if e['facts'] else '', 0) + e['support'] / 2
            target = max(choices, key=utility)
        queue, queued = [], set()
        if target:
            queue.append((target, False, True))
            queued.add(target['id'])
        natural = [e for e in choices if e['id'] not in queued]
        for i in range(min(2, len(natural))):
            candidate = natural.pop(rng.randrange(len(natural)))
            queue.append((candidate, False, False))
            queued.add(candidate['id'])
        tried = set()
        today_count = 0
        while queue and today_count < 32:
            e, guaranteed, stamped = queue.pop(0)
            if e['id'] in tried or not eligible(e):
                continue
            tried.add(e['id'])
            chance = min(.98, e['chance'] + (.55 if stamped else 0))
            if not guaranteed and rng.random() >= chance:
                continue
            newly = set(e['facts']) - facts
            facts.update(newly)
            fired.add(e['id'])
            support += e['support']
            today_count += 1
            for candidate in events:
                if candidate['id'] in queued or candidate['id'] in tried:
                    continue
                if eligible(candidate) and newly.intersection(candidate['all'] + candidate['any']):
                    queue.append((candidate, False, False))
                    queued.add(candidate['id'])
        max_daily = max(max_daily, today_count)
        total += today_count
    return 'goose_candidate' in facts and support >= 15, support, total, max_daily


def main():
    events = parse_rules()
    facts = validate(events)
    print(f'Catalog PASS: {len(events)} events, {len(facts)} distinct facts, unique IDs, reachable prerequisites.')
    for title, strategy in [
        ('Natural outcomes only', False),
        ('One targeted strategic nudge per day', True),
    ]:
        results = [simulate(events, seed, strategy) for seed in range(1000)]
        successes = sum(outcome[0] for outcome in results)
        supports = sorted(outcome[1] for outcome in results)
        chains = sorted(outcome[3] for outcome in results)
        print(f'{title}: {successes / 10:.1f}% win rate, median support {supports[500]}, median max daily chain {chains[500]}')
    print('Note: balance simulation uses Python RNG, approximate nudges and does not validate Godot execution.')


if __name__ == '__main__':
    main()
