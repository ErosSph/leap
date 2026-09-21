"""Traverse hardware scopes already selected and expanded by Slang."""
import re
from contextvars import ContextVar


symbol_names = ContextVar("rtl2lean_symbol_names", default={})


def active_symbols(scope):
    for symbol in scope:
        kind = str(symbol.kind).rsplit(".", 1)[-1]
        if kind == "GenerateBlock":
            if not symbol.isUninstantiated:
                yield from active_symbols(symbol)
        elif kind == "GenerateBlockArray":
            if not symbol.isUninstantiated:
                for entry in symbol.entries:
                    if not entry.isUninstantiated:
                        yield from active_symbols(entry)
        else:
            yield symbol


def relative_path(symbol, scope):
    prefix = str(scope.hierarchicalPath) + "."
    path = str(symbol.hierarchicalPath)
    if not path.startswith(prefix):
        raise ValueError(f"symbol {path} not within scope {scope.hierarchicalPath}")
    return path[len(prefix):]


def flat_path(path):
    path = re.sub(r"\[(-?\d+)\]", lambda m: "__idx" + m[1].replace("-", "neg"), path)
    return path.replace(".", "__")


def resolved_name(symbol):
    names = symbol_names.get()
    return names.get(symbol, names.get(str(symbol.hierarchicalPath), str(symbol.name)))
