# Convenience functions for handling and parsing verilog source files
import argparse
from pyverilog.vparser.parser import parse
from pyverilog.ast_code_generator.codegen import ASTCodeGenerator
import sys, os

codegen = ASTCodeGenerator()

def extract_module_info(ast):
    modules = []
    for desc in getattr(ast, "description", []).definitions:
        if desc.__class__.__name__ != "ModuleDef":
            continue
        module_name = desc.name
        ports = []

        if not desc.portlist:
            modules.append((module_name, ports))
            continue

        for item in desc.portlist.ports:
            decl = getattr(item, "first", None)
            if decl is None:
                pname = getattr(item, "name", None)
                if pname:
                    ports.append(("input", "", pname))
                continue

            direction = decl.__class__.__name__.lower()
            width = ""
            if getattr(decl, "width", None):
                msb = codegen.visit(decl.width.msb)
                lsb = codegen.visit(decl.width.lsb)
                width = f"[{msb}:{lsb}]"
            name = decl.name
            ports.append((direction, width, name))

        modules.append((module_name, ports))
    return modules

def generate_instantiation(module_name, ports, declared_signals, instance_name=""):
    decl_lines = []
    conn_lines = []

    if instance_name == "":
        instance_name = f"u_{module_name}"

    for direction, width, name in ports:
        if name in declared_signals:
            # Skip if already declared
            conn_lines.append(f"    .{name}({name})")
            continue

        w = f"{width} " if width else ""
        if direction == "input":
            decl_lines.append(f"  reg {w}{name};")
        else:
            decl_lines.append(f"  wire {w}{name};")

        declared_signals.add(name)
        conn_lines.append(f"    .{name}({name})")

    inst = f"  {module_name} {instance_name} (\n" + ",\n".join(conn_lines) + "\n  );"
    return "\n".join(decl_lines) + "\n\n" + inst

def cleanup_pyverilog_artifacts():
    for junk in ["parser.out", "parsetab.py", "parsetab.pyc"]:
        try:
            os.remove(junk)
        except FileNotFoundError:
            pass
    pycache = "__pycache__"
    if os.path.isdir(pycache):
        for fn in os.listdir(pycache):
            if fn.startswith("parsetab.") and (fn.endswith(".pyc") or fn.endswith(".pyo")):
                try:
                    os.remove(os.path.join(pycache, fn))
                except FileNotFoundError:
                    pass
