import yaml
from jinja2 import Template
from pathlib import Path
from typing import List, Dict

HERE = Path(__file__).parent


def merge_conda(*args: List[Dict]):
    """
    Merge multiple conda environments
    """
    # TODO: split on version number, have users take precedence
    env = {"channels": [], "dependencies": []}
    for arg in args:
        env['channels'].extend(arg.get("channels", []))
        env['dependencies'].extend(arg.get("dependencies", []))

    return env


def read_conda(repo):
    envs = []
    with open(HERE.joinpath("base.yaml")) as f:
        envs.append(yaml.safe_load(f))

    for ext in "yaml", "yml":
        p = repo.joinpath(f"environment.{ext}")
        if p.exists():
            with open(p) as f:
                envs.append(yaml.safe_load(f))
    return envs


def read_apt(repo):
    p = repo.joinpath("apt.txt")
    if p.exists():
        with open(p) as f:
            apt = f.read()
        return apt


def translate(env):
    channels = env['channels']
    if len(channels) == 0:
        default = 'defaults'
    else:
        default = channels[0]

    flat = []
    for dep in env['dependencies']:
        if "::" not in dep:
            dep = f"{default}::{dep}"
        flat.append(dep)

    flat = " \\\n  ".join(flat)
    return flat


if __name__ == "__main__":
    base = Path(".")
    envs = read_conda(base)
    env = merge_conda(*envs)
    conda_packages = translate(env)
    apt_pkgs = read_apt(base)
    if apt_pkgs:
        apt_pkgs = ' '.join(apt_pkgs.split('\n'))
        apt = (f"RUN apt-get update && apt-get install -y "
               f"{apt_pkgs} && aptrm -rf /var/lib/apt/lists/*")
    else:
        apt = ""

    with open(HERE.joinpath("Dockerfile.tpl")) as f:
        template = Template(f.read())

    apt_file = base.joinpath("apt.txt")
    dockerfile = template.render(apt=apt, conda_packages=conda_packages)

    with open("Dockerfile", "w") as f:
        f.write(dockerfile)
