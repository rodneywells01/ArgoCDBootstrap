"""Offline rendering guardrails; does not establish live auth or capacity."""
import os
import subprocess
import unittest
from pathlib import Path
import yaml

ROOT = Path(__file__).resolve().parents[1]
HELM = os.environ.get('HELM', 'helm')

def render(*settings, fixture=True):
    args = [HELM, 'template', 'test-app', str(ROOT / 'charts/private-web-app')]
    if fixture:
        args += ['-f', str(ROOT / 'examples/private-web-app/values.yaml')]
    for setting in settings:
        args += ['--set', setting]
    return subprocess.run(args, capture_output=True, text=True)

class HostingTests(unittest.TestCase):
    def test_disabled_default_is_empty(self):
        result = render(fixture=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(list(yaml.safe_load_all(result.stdout)), [])

    def test_private_single_writer(self):
        result = render()
        self.assertEqual(result.returncode, 0, result.stderr)
        docs = {d['kind']: d for d in yaml.safe_load_all(result.stdout) if d}
        self.assertNotIn('Ingress', docs)
        self.assertNotIn('PersistentVolumeClaim', docs)
        self.assertNotIn('Secret', docs)
        self.assertEqual(docs['Service']['spec']['type'], 'ClusterIP')
        self.assertEqual(docs['Service']['spec']['ports'][0]['targetPort'], 'proxy')
        spec = docs['Deployment']['spec']
        self.assertEqual(spec['replicas'], 1)
        self.assertEqual(spec['strategy']['type'], 'Recreate')
        self.assertFalse(spec['template']['spec']['automountServiceAccountToken'])
        self.assertEqual(docs['NetworkPolicy']['spec']['ingress'], [])

    def test_required_configuration_fails_closed(self):
        for override in ('auth.existingSecret=', 'image.digest=latest', 'persistence.existingClaim=', 'ingress.enabled=true'):
            with self.subTest(override=override):
                self.assertNotEqual(render(override).returncode, 0)

    def test_tls_ingress_targets_only_proxy(self):
        result = render('ingress.enabled=true', 'ingress.className=verified-controller', 'ingress.tlsSecret=app-tls', 'networkPolicy.ingressNamespaceLabels.platform=ingress')
        self.assertEqual(result.returncode, 0, result.stderr)
        docs = {d['kind']: d for d in yaml.safe_load_all(result.stdout) if d}
        self.assertEqual(docs['Ingress']['spec']['tls'][0]['secretName'], 'app-tls')
        self.assertEqual(docs['NetworkPolicy']['spec']['ingress'][0]['ports'][0]['port'], 4180)

    def test_audit_role_is_read_only_without_secret_access(self):
        role = yaml.safe_load((ROOT / 'examples/audit-reader-role.yaml').read_text())
        for rule in role['rules']:
            self.assertEqual(set(rule['verbs']), {'get', 'list'})
            self.assertFalse({'secrets', 'pods/exec', 'pods/log', '*'} & set(rule['resources']))

    def test_budget_and_auth_allowlist(self):
        result = render()
        docs = {d['kind']: d for d in yaml.safe_load_all(result.stdout) if d}
        containers = docs['Deployment']['spec']['template']['spec']['containers']
        self.assertEqual(containers[0]['resources']['requests'], {'cpu': '100m', 'memory': '256Mi'})
        self.assertEqual(containers[1]['resources']['requests'], {'cpu': '10m', 'memory': '32Mi'})
        self.assertIn('--authenticated-emails-file=/allowlist/allowed-emails', containers[1]['args'])
        self.assertNotIn('--email-domain=*', containers[1]['args'])

    def test_bootstrap_does_not_activate_examples(self):
        root = yaml.safe_load((ROOT / 'bootstrap-root-application.yaml').read_text())
        self.assertNotIn('examples', root['spec']['source']['directory']['include'])
        self.assertNotIn('charts', root['spec']['source']['directory']['include'])

if __name__ == '__main__':
    unittest.main()
