from pathlib import Path

import jsonschema_specifications


package_root = Path(jsonschema_specifications.__file__).parent
schemas_root = package_root / "schemas"

datas = [
    (
        str(path),
        str(Path("jsonschema_specifications") / path.relative_to(package_root).parent),
    )
    for path in schemas_root.rglob("*")
    if path.is_file() and not path.name.endswith(":Zone.Identifier")
]
