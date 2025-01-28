import json
import subprocess
import shutil
from pathlib import Path
from typing import List, Any


def find_vyper_contracts(contracts_dir: str) -> List[Path]:
    """Recursively find all .vy files in the contracts directory"""
    contracts_path = Path(contracts_dir)
    return list(contracts_path.rglob("*.vy"))


def clean_directory(directory: Path):
    """Remove and recreate the specified directory"""
    if directory.exists():
        shutil.rmtree(directory)
    directory.mkdir(parents=True, exist_ok=True)


def vyper_to_python_type(vyper_type: str) -> str:
    """Convert Vyper types to Python types"""
    type_mapping = {
        'address': 'str',
        'bool': 'bool',
        'string': 'str',
        'bytes32': 'bytes',
        'uint256': 'int',
        'int256': 'int',
        'uint8': 'int',
        'int8': 'int',
        'bytes': 'bytes',
        # Add any other basic types you encounter
    }

    try:
        # Handle tuple types (structs)
        if vyper_type.startswith('tuple'):
            # Handle empty tuple
            if vyper_type == 'tuple':
                return 'Tuple'

            # Find the opening and closing parentheses
            start_idx = vyper_type.find('(')
            end_idx = vyper_type.rfind(')')

            if start_idx == -1 or end_idx == -1:
                print(f"Warning: Malformed tuple type: {vyper_type}, falling back to Any")
                return 'Any'

            # Extract the components
            components_str = vyper_type[start_idx + 1:end_idx]
            if not components_str:
                return 'Tuple'

            # Handle nested tuples by counting parentheses
            components = []
            current = ''
            paren_count = 0

            for char in components_str:
                if char == '(' or char == '[':
                    paren_count += 1
                elif char == ')' or char == ']':
                    paren_count -= 1
                elif char == ',' and paren_count == 0:
                    if current:
                        components.append(current.strip())
                    current = ''
                    continue
                current += char

            if current:
                components.append(current.strip())

            component_types = [vyper_to_python_type(comp) for comp in components]
            return f"Tuple[{', '.join(component_types)}]"

        # Handle array types with dimensions
        if '[' in vyper_type:
            base_type = vyper_type[:vyper_type.index('[')]
            dimensions = vyper_type.count('[')
            python_type = type_mapping.get(base_type, 'Any')

            # Wrap in List[] for each dimension
            for _ in range(dimensions):
                python_type = f"List[{python_type}]"
            return python_type

        return type_mapping.get(vyper_type, 'Any')

    except Exception as e:
        print(f"Warning: Error converting type {vyper_type}: {str(e)}, falling back to Any")
        return 'Any'


def generate_type_file(contract_name: str, abi: List[dict], output_dir: Path) -> bool:
    """Generate a Python type file and ABI JSON from ABI data"""
    try:
        content = [
            "from typing import Protocol, List, Any, Optional, Tuple\n\n",
            f"class {contract_name}Contract(Protocol):\n",
            f"    \"\"\"Generated type stub for {contract_name}\"\"\"\n\n"
        ]

        for item in abi:
            if item['type'] == 'function':
                inputs = [
                    f"{inp.get('name', f'arg{i}')}: {vyper_to_python_type(inp['type'])}"
                    for i, inp in enumerate(item.get('inputs', []))
                ]

                outputs = item.get('outputs', [])
                if len(outputs) == 0:
                    return_type = 'None'
                elif len(outputs) == 1:
                    return_type = vyper_to_python_type(outputs[0]['type'])
                else:
                    return_type = f"Tuple[{', '.join(vyper_to_python_type(out['type']) for out in outputs)}]"

                func_def = f"    def {item['name']}({', '.join(inputs)}) -> {return_type}:\n        ...\n\n"
                content.append(func_def)

        output_path = output_dir / f"{contract_name}.py"
        output_path.write_text(''.join(content))
        print(f"Generated type stub for {contract_name}:")
        print(f"  - {output_path}")
        return True

    except Exception as e:
        print(f"Error generating types for {contract_name}: {str(e)}")
        return False


def generate_contract_files(contracts_dir: str = "contracts", output_dir: str = "generated"):
    """Generate type stubs and ABI files for all Vyper contracts"""
    # Create Path objects
    output_path = Path(output_dir)
    types_dir = output_path / "types"
    abi_dir = output_path / "abi"  # New directory for ABI files

    # Clean and recreate directories
    clean_directory(output_path)
    clean_directory(types_dir)
    clean_directory(abi_dir)  # Clean ABI directory

    # Create __init__.py files
    output_path.joinpath("__init__.py").write_text("")
    types_dir.joinpath("__init__.py").write_text("")

    # Find all Vyper contracts
    contracts = find_vyper_contracts(contracts_dir)
    print(f"\nFound {len(contracts)} Vyper contracts")

    successful_contracts = []

    for contract_path in contracts:
        try:
            contract_name = contract_path.stem

            # Get ABI directly from vyper compiler
            abi_result = subprocess.run(
                ["vyper", "-f", "abi", str(contract_path)],
                capture_output=True,
                text=True
            )

            if abi_result.returncode != 0:
                print(f"\nError getting ABI for {contract_path}:")
                print(abi_result.stderr)
                continue

            if not abi_result.stdout.strip():
                print(f"\nWarning: Empty ABI generated for {contract_path}, skipping")
                continue

            # Parse ABI and generate type file and save ABI
            abi = json.loads(abi_result.stdout)

            # Save ABI file
            abi_file = abi_dir / f"{contract_name}.json"
            abi_file.write_text(json.dumps(abi, indent=2))
            print(f"  - {abi_file}")

            # Generate type file
            if generate_type_file(contract_name, abi, types_dir):
                successful_contracts.append(contract_name)

        except Exception as e:
            print(f"\nError processing {contract_path}: {str(e)}")

    if successful_contracts:
        # Generate __init__.py to expose all types
        init_content = []
        for contract_name in successful_contracts:
            init_content.append(f"from .{contract_name} import {contract_name}Contract\n")

        types_dir.joinpath("__init__.py").write_text(''.join(init_content))
        print(f"\nGenerated type stubs in {types_dir}")
    else:
        print("\nNo contracts were successfully processed")


if __name__ == "__main__":
    generate_contract_files()
