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


def get_code_snippet(relative_file_path, code_line):
    # Assume Maven.
    # TODO: Acquire from environment variable "SOURCE_BASE_DIR".
    file_path = f"src/main/java/{relative_file_path}"

    # TODO: Exception handling.
    with open(file_path, 'r') as file:
        lines = file.readlines()
    start_line = code_line
    end_line = start_line + 10
    start_line = max(0, start_line - 10)
    end_line = min(len(lines), end_line)
    return "".join(lines[start_line:end_line])


def construct_prompt(target_name, target_id, text, code_snippet):
    prompt = """
SAST 툴이 아래 자바 코드가 "{}-{}: {}" 취약점을 가지고 있다고 진단하였습니다:
---
{}
---
이 코드가 실제로 취약한가요?
만약 그렇다면 조치할 수 있는 방법과 조치된 코드를 제시해 주세요.
답변은 한국어로 해주세요.
""".format(target_name, target_id, text, code_snippet)
    return prompt
