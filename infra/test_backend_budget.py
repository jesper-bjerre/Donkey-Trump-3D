import importlib.util
from datetime import datetime, timezone
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('budget', Path(__file__).with_name('configure-backend-budget.py'))
budget = importlib.util.module_from_spec(spec); spec.loader.exec_module(budget)


class BudgetTests(unittest.TestCase):
    def reference(self):
        return {'properties': {'currentSpend': {'unit': 'DKK'}, 'notifications': {
            'old': {'contactEmails': ['owner@example.invalid', 'unrelated@example.invalid']}}}}

    def test_owner_only_alerts_cover_project_and_allow_for_vat(self):
        actual = budget.payload(self.reference(), 'owner@example.invalid', datetime(2026, 9, 26, tzinfo=timezone.utc))['properties']
        self.assertEqual(100, actual['amount'] * 1.25)
        self.assertEqual({'name': 'Project', 'operator': 'In', 'values': ['DonkeyTrump']}, actual['filter']['tags'])
        for notification in actual['notifications'].values():
            self.assertEqual(['owner@example.invalid'], notification['contactEmails'])
            self.assertEqual([], notification['contactGroups'])
            self.assertTrue(notification['enabled'])
        self.assertEqual({50, 75, 100}, {n['threshold'] for n in actual['notifications'].values() if n['thresholdType'] == 'Actual'})
        self.assertEqual('2026-09-01T00:00:00Z', actual['timePeriod']['startDate'])

    def test_foreign_currency_cannot_create_wrong_currency_budget(self):
        reference = self.reference(); reference['properties']['currentSpend']['unit'] = 'EUR'
        with self.assertRaises(ValueError): budget.payload(reference, 'owner@example.invalid', datetime.now(timezone.utc))

    def test_cannot_silently_add_a_new_recipient(self):
        with self.assertRaises(ValueError): budget.payload(self.reference(), 'new@example.invalid', datetime.now(timezone.utc))


if __name__ == '__main__': unittest.main()
