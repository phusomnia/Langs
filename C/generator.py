import sys
from pathlib import Path
from clang.cindex import (
    Index,
    CursorKind,
    StorageClass,
    TranslationUnit
)

class HeaderGenerator:

    def __init__(self):
        self.index = Index.create()

        self.source_file = None

        self.enums = []
        self.structs = []
        self.unions = []
        self.typedefs = []
        self.functions = []

        self.function_signatures = set()

    def parse(self, source):
        self.source_file = Path(source).resolve()

        tu = self.index.parse(
            source,
            args=[
                "-std=c11",
                "-nostdinc"
            ],
            options=TranslationUnit.PARSE_INCOMPLETE
        )

        for diag in tu.diagnostics:
            print(
                diag,
                file=sys.stderr
            )

        self.collect(tu.cursor)

    def is_from_source(self, cursor):
        loc = cursor.location

        if loc.file is None:
            return False

        try:
            return (
                Path(loc.file.name).resolve()
                == self.source_file
            )
        except Exception:
            return False

    def collect(self, cursor):

        if self.is_from_source(cursor):

            #
            # typedef
            #
            if cursor.kind == CursorKind.TYPEDEF_DECL:

                typedef = {
                    "name": cursor.spelling,
                    "type": (
                        cursor
                        .underlying_typedef_type
                        .spelling
                    )
                }

                if (
                    typedef["name"]
                    and not any(
                        t["name"] == typedef["name"]
                        for t in self.typedefs
                    )
                ):
                    for prefix, collection in [
                        ("enum ", self.enums),
                        ("struct ", self.structs),
                        ("union ", self.unions),
                    ]:
                        if typedef["type"].startswith(prefix):
                            name = typedef["type"][len(prefix):]
                            if any(c["name"] == name for c in collection):
                                break
                    else:
                        self.typedefs.append(typedef)

            #
            # enum
            #
            elif (
                cursor.kind
                == CursorKind.ENUM_DECL
                and cursor.is_definition()
            ):

                enum = {
                    "name": cursor.spelling,
                    "values": []
                }

                for child in cursor.get_children():

                    if (
                        child.kind
                        == CursorKind.ENUM_CONSTANT_DECL
                    ):
                        enum["values"].append(
                            (
                                child.spelling,
                                child.enum_value
                            )
                        )

                if (
                    enum["name"]
                    and not any(
                        e["name"] == enum["name"]
                        for e in self.enums
                    )
                ):
                    self.enums.append(
                        enum
                    )

            #
            # struct
            #
            elif (
                cursor.kind
                == CursorKind.STRUCT_DECL
                and cursor.is_definition()
            ):

                struct = {
                    "name": cursor.spelling,
                    "fields": []
                }

                for child in cursor.get_children():

                    if (
                        child.kind
                        == CursorKind.FIELD_DECL
                    ):
                        struct["fields"].append(
                            (
                                child.type.spelling,
                                child.spelling
                            )
                        )

                if (
                    struct["name"]
                    and not any(
                        s["name"] == struct["name"]
                        for s in self.structs
                    )
                ):
                    self.structs.append(
                        struct
                    )

            #
            # union
            #
            elif (
                cursor.kind
                == CursorKind.UNION_DECL
                and cursor.is_definition()
            ):

                union = {
                    "name": cursor.spelling,
                    "fields": []
                }

                for child in cursor.get_children():

                    if (
                        child.kind
                        == CursorKind.FIELD_DECL
                    ):
                        union["fields"].append(
                            (
                                child.type.spelling,
                                child.spelling
                            )
                        )

                if (
                    union["name"]
                    and not any(
                        u["name"] == union["name"]
                        for u in self.unions
                    )
                ):
                    self.unions.append(
                        union
                    )

            #
            # functions
            #
            elif (
                cursor.kind
                == CursorKind.FUNCTION_DECL
            ):

                if (
                    cursor.storage_class
                    == StorageClass.STATIC
                ):
                    pass
                else:

                    fn = {
                        "name": cursor.spelling,
                        "return": (
                            cursor.result_type.spelling
                        ),
                        "params": [],
                        "is_variadic": cursor.type.spelling.endswith(', ...)')
                    }

                    for arg in cursor.get_arguments():

                        fn["params"].append(
                            (
                                arg.type.spelling,
                                arg.spelling
                            )
                        )

                    signature = (
                        fn["name"],
                        tuple(
                            p[0]
                            for p in fn["params"]
                        )
                    )

                    if (
                        signature
                        not in self.function_signatures
                    ):
                        self.function_signatures.add(
                            signature
                        )

                        self.functions.append(
                            fn
                        )

        for child in cursor.get_children():
            self.collect(child)

    def generate(self):

        guard = (
            self.source_file.stem.upper()
            + "_H"
        )

        lines = []

        lines.append(
            f"#ifndef {guard}"
        )
        lines.append(
            f"#define {guard}"
        )
        lines.append("")

        #
        # typedefs
        #
        for typedef in self.typedefs:

            lines.append(
                f"typedef {typedef['type']} "
                f"{typedef['name']};"
            )

        if self.typedefs:
            lines.append("")

        #
        # enums
        #
        for enum in self.enums:

            lines.append(
                "typedef enum {"
            )

            for name, value in enum["values"]:

                lines.append(
                    f"    {name} = {value},"
                )

            lines.append(
                f"}} {enum['name']};"
            )

            lines.append("")

        #
        # structs
        #
        for struct in self.structs:

            lines.append(
                "typedef struct {"
            )

            for (
                field_type,
                field_name
            ) in struct["fields"]:

                lines.append(
                    f"    {field_type} "
                    f"{field_name};"
                )

            lines.append(
                f"}} {struct['name']};"
            )

            lines.append("")

        #
        # unions
        #
        for union in self.unions:

            lines.append(
                "typedef union {"
            )

            for (
                field_type,
                field_name
            ) in union["fields"]:

                lines.append(
                    f"    {field_type} "
                    f"{field_name};"
                )

            lines.append(
                f"}} {union['name']};"
            )

            lines.append("")

        #
        # functions
        #
        for fn in self.functions:

            params = []

            for (
                ptype,
                pname
            ) in fn["params"]:

                if pname:
                    params.append(
                        f"{ptype} {pname}"
                    )
                else:
                    params.append(
                        ptype
                    )

            if fn["is_variadic"]:
                params.append("...")

            if not params:
                params.append(
                    "void"
                )

            lines.append(
                f"{fn['return']} "
                f"{fn['name']}("
                f"{', '.join(params)});"
            )

        lines.append("")
        lines.append(
            f"#endif /* {guard} */"
        )

        return "\n".join(lines)

    def write(self, output):

        with open(
            output,
            "w",
            encoding="utf-8"
        ) as fp:

            fp.write(
                self.generate()
            )


def main():

    argv = sys.argv[1:]

    if len(argv) != 2:

        print("Usage:")
        print(
            "  python generator.py "
            "<source.c> <dest.h>"
        )
        return

    source = argv[0]
    dest = argv[1]

    gen = HeaderGenerator()

    gen.parse(source)
    gen.write(dest)

    print(
        f"Generated {dest}"
    )


if __name__ == "__main__":
    main()