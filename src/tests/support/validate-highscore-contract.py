#!/usr/bin/env python3
"""Validate the OpenAPI 3.1 schemas and every supplied media example (PyYAML + jsonschema)."""
from pathlib import Path
import yaml
from jsonschema import Draft202012Validator, FormatChecker
root = Path(__file__).resolve().parents[3]
document = yaml.safe_load((root / 'specs/001-global-highscores/contracts/highscores.openapi.yaml').read_text())
assert document['openapi'] == '3.1.0'
count = 0

def visit(node):
    global count
    if isinstance(node, dict):
        if 'schema' in node:
            schema = dict(node['schema'], components=document['components'])
            validator = Draft202012Validator(schema, format_checker=FormatChecker())
            Draft202012Validator.check_schema(schema)
            if 'example' in node:
                validator.validate(node['example']); count += 1
            for example in node.get('examples', {}).values():
                if 'value' in example:
                    validator.validate(example['value']); count += 1
        for child in node.values(): visit(child)
    elif isinstance(node, list):
        for child in node: visit(child)

for schema in document['components']['schemas'].values(): Draft202012Validator.check_schema(schema)
visit(document)
assert count > 0
print(f'PASS: {len(document["components"]["schemas"])} OpenAPI schemas; {count} media/header examples')
