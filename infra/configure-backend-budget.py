#!/usr/bin/env python3
"""Configure project cost warnings for the existing owner's Azure budget recipient.

Run as the signed-in operator, not a deployment identity. Tokens and email addresses
stay in process memory and are never printed or written into repository files.
"""
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess
import urllib.error
import urllib.request

CONFIG = json.loads((Path(__file__).with_name('backend-environments.json')).read_text())
BUDGET_NAME = 'donkeytrump-monthly-budget'
NET_AMOUNT_DKK = 80  # DKK 100 including 25% VAT; Azure cost budgets exclude tax.


def payload(reference, owner, start):
    properties = reference['properties']
    if properties.get('currentSpend', {}).get('unit') != 'DKK':
        raise ValueError('Verify DKK billing currency before configuring the budget')
    recipients = {email.lower() for n in properties.get('notifications', {}).values()
                  for email in n.get('contactEmails', [])}
    if owner.lower() not in recipients:
        raise ValueError('Signed-in owner must already receive the existing Azure budget alerts')
    notifications = {}
    for kind, threshold in [('Actual', 50), ('Actual', 75), ('Actual', 100), ('Forecasted', 90)]:
        notifications[f'{kind.lower()}_{threshold}'] = {
            'enabled': True, 'operator': 'GreaterThanOrEqualTo', 'threshold': threshold,
            'thresholdType': kind, 'contactEmails': [owner], 'contactGroups': [],
            'contactRoles': [], 'locale': 'en-us'}
    return {'properties': {
        'category': 'Cost', 'amount': NET_AMOUNT_DKK, 'timeGrain': 'Monthly',
        # Match both apps and storage across groups. Shared plans have other tags.
        'filter': {'tags': {'name': 'Project', 'operator': 'In', 'values': ['DonkeyTrump']}},
        'timePeriod': {'startDate': start.strftime('%Y-%m-01T00:00:00Z'),
                       'endDate': start.replace(day=1, year=start.year + 10).strftime('%Y-%m-01T00:00:00Z')},
        'notifications': notifications}}


def main():
    def cli(*args):
        result = subprocess.run(['az', *args, '-o', 'json'], capture_output=True, text=True, check=True)
        return json.loads(result.stdout)
    account = cli('account', 'show', '--subscription', CONFIG['subscriptionId'])
    if account['user']['type'] != 'user':
        raise RuntimeError('Run using the existing human operator session')
    tagged = cli('resource', 'list', '--subscription', CONFIG['subscriptionId'], '--tag', 'Project=DonkeyTrump')
    tagged_names = {r['name'] for r in tagged}
    if any(c[key] not in tagged_names for c in CONFIG['environments'].values() for key in ['appName', 'storageAccount']):
        raise RuntimeError('Both apps and storage accounts must carry the project cost tag')
    token = cli('account', 'get-access-token', '--subscription', CONFIG['subscriptionId'],
                '--resource', 'https://management.azure.com/')['accessToken']
    base = 'https://management.azure.com/subscriptions/' + CONFIG['subscriptionId'] + '/providers/Microsoft.Consumption/budgets/'

    def request(name, body=None, missing_ok=False):
        req = urllib.request.Request(base + name + '?api-version=2024-08-01',
            data=json.dumps(body).encode() if body else None,
            method='PUT' if body else 'GET',
            headers={'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json'})
        try:
            with urllib.request.urlopen(req, timeout=60) as response:
                return json.load(response)
        except urllib.error.HTTPError as error:
            if missing_ok and error.code == 404:
                return None
            raise RuntimeError(f'Azure budget request failed with HTTP {error.code}') from None

    body = payload(request('Budget'), account['user']['name'], datetime.now(timezone.utc))
    existing = request(BUDGET_NAME, missing_ok=True)
    if existing:
        if any(existing['properties'].get(k) != body['properties'][k] for k in ['amount', 'filter', 'category', 'timeGrain']):
            raise RuntimeError('Existing budget differs; refusing to change its scope or limit')
        body['eTag'] = existing['eTag']
        body['properties']['timePeriod'] = existing['properties']['timePeriod']
    request(BUDGET_NAME, body)
    actual = request(BUDGET_NAME)['properties']
    for field in ['amount', 'filter', 'timeGrain', 'notifications', 'timePeriod']:
        if actual.get(field) != body['properties'][field]:
            raise RuntimeError('Budget readback differs: ' + field)
    print(json.dumps({'budget': BUDGET_NAME, 'currency': 'DKK', 'netMonthlyAmount': actual['amount'],
        'includingVatDkk': actual['amount'] * 1.25, 'scope': actual['filter'],
        'timePeriod': actual['timePeriod'], 'notifications': {
            k: {f: v[f] for f in ['enabled', 'threshold', 'thresholdType']} for k, v in actual['notifications'].items()},
        'recipient': 'signed-in owner, already configured on existing subscription budget',
        'recipientCount': 1, 'testNotificationSent': False, 'hardSpendingCap': False}))


if __name__ == '__main__':
    main()
