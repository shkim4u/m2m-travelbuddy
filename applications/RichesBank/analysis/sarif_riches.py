from sarif import loader
import json

import attrs
import sarif_om

def get_sarif_class(schema_ref):
    class_name = schema_ref.split('/')[-1]
    class_name = class_name[0].capitalize() + class_name[1:]
    return getattr(sarif_om, class_name)

def get_field_name(schema_property_name, cls):
    for field in attrs.fields(cls):
        if field.metadata.get('schema_property_name') == schema_property_name:
            return field.name
    return schema_property_name

def get_schema_properties(schema, schema_ref):
    cursor = schema
    for part in schema_ref.split('/'):
        if part == '#':
            cursor = schema
        else:
            cursor = cursor[part]
    return cursor['properties']

def materialize(data, cls, schema, schema_ref):
    fields = {}
    extras = {}
    props = get_schema_properties(schema, schema_ref)

    for key, value in data.items():
        field_name = get_field_name(key, cls)

        if key not in props:
            extras[field_name] = value
            continue

        if '$ref' in props[key]:
            schema_ref = props[key]['$ref']
            field_cls = get_sarif_class(schema_ref)
            fields[field_name] = materialize(value, field_cls, schema, schema_ref)

        elif 'items' in props[key]:
            schema_ref = props[key]['items'].get('$ref')
            if schema_ref:
                field_cls = get_sarif_class(schema_ref)
                fields[field_name] = [materialize(v, field_cls, schema, schema_ref) for v in value]
            else:
                fields[field_name] = value
        else:
            fields[field_name] = value

    obj = cls(**fields)
    obj.__dict__.update(extras)
    return obj

path_to_sarif_file = "spotbugs-sarif.json"

sarif_data = loader.load_sarif_file(path_to_sarif_file)
issue_count_by_severity = sarif_data.get_result_count_by_severity()
error_histogram = sarif_data.get_issue_code_histogram("error")
warning_histogram = sarif_data.get_issue_code_histogram("warning")
note_histogram = sarif_data.get_issue_code_histogram("note")

print(f"Issue count by severity: {issue_count_by_severity}")
print(f"Error histogram: {error_histogram}")
print(f"Warning histogram: {warning_histogram}")
print(f"Note histogram: {note_histogram}")

with open('spotbugs-sarif.json', 'r') as file:
    data = json.load(file)

with open('sarif-schema-2.1.0.json', 'r') as file:
    schema = json.load(file)

sarif_log = materialize(data, sarif_om.SarifLog, schema, '#')
print(sarif_log)
print("===")

sarif_runs = sarif_log.runs
run = sarif_runs[0]
print(run)

print("===")
results = run.results
print(results)
