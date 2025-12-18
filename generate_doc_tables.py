#!/usr/bin/env python3
# coding=UTF-8
import os
import yaml

def main():
    # This should be changed if stash or project gets moved / restructured
    stash_base_url = "https://stash.qvantel.net/projects/CP/repos/k8s-platform-addon-operator/browse/modules/"
    readme_file = "./README.md"
    module_dir = "./modules/"
    component_list_dest_file = "./component_table.md"
    # Generates the component table
    generate_module_components(module_dir, component_list_dest_file, stash_base_url)
    # Generates a table of modules with their descriptions
    module_table = generate_module_list(module_dir)
    # Writes that table to README.md between TABLEMARKER tags.
    add_table_to_readme(readme_file, module_table)

def list_charts(module, module_dir):
    # Since our chart folder is always camelCase, generating that based on the module name
    split_name = module.split("-")
    split_name.pop(0)
    capitalized_list = [word.capitalize() for word in split_name]
    camelCase = capitalized_list[0].lower() + "".join(capitalized_list[1:])
    # Now it's possible to generate the path for the Chart
    chart_path = module_dir + module + "/charts/" + camelCase + "/Chart.yaml"
    chart_data = []
    # If the module has no chart, return an empty cell
    try:
        chart_file = open(chart_path)
    except FileNotFoundError:
        return ""
    # If file could be accessed, loading it as yaml to iterate
    chart_yaml = yaml.safe_load(chart_file)
    chart_file.close()
    for key, value in chart_yaml.items():
        # Upstream charts are module dependencies
        if key == "dependencies":
            for field in value:
                # Not every Chart has a repository (600-ksix-platform)
                if "repository" in field.keys():
                    # Wrapping data in a codeblock and adding a HTML line change in case there's multiple Charts
                    chart_data.append("```" + field["repository"] + "/" + field["name"] + ":" +  field["version"] + "```" + "<br>")
                else:
                    chart_data.append("```" + field["name"] + ":" +  field["version"] + "```" + "<br>")
    chart_data = sorted(set(chart_data))
    chart_data = "".join(chart_data)
    return chart_data

def list_images(module, module_dir):
    image_lock_path = module_dir + module + "/Images.lock"
    chart_data = ""
    # If the module has no lockfile, return an empty cell
    try:
        image_lock_file = open(image_lock_path)
    except FileNotFoundError:
        return chart_data
    # If file could be accessed, loading it as yaml to iterate
    image_lock_yaml = yaml.safe_load(image_lock_file)
    image_lock_file.close()
    for key, value in image_lock_yaml.items():
        if key == "images":
            for field in value:
                # Wrapping image and its name in a codeblock
                chart_data += field["name"] + " - " + "```" + field["image"] + "``` "
                # Architectures are individual digests, cutting the redundant "linux/"
                for data in field["digests"]:
                    chart_data += " ```" + data["arch"][6:] + "```"
                # Finishing with a HTML line change in case there's multiple images
                chart_data += "<br>"
    return chart_data

def is_multiarch(row):
    armcount = row.count("amd64")
    amdcount = row.count("arm64")
    # If the architecture counts match, it must be multiarch.
    if armcount == amdcount:
        return "✔️"
    else:
        return "❌"

def module_to_url(module, base_url):
    markdown_url = "[" + module + "](" + base_url + module + ")"
    return markdown_url

def get_brief(module, module_dir):
    readme_path = module_dir + module + "/README.md"
    brief = ""
    # If module has no README.md, returning its name to use as description.
    try:
        readme_file = open(readme_path)
    except FileNotFoundError:
        return module
    # If file could be accessed, loading it to iterate
    line = readme_file.readline()
    
    while line:
        # If BRIEF tag is found, move one line forward and 
        if "<!-- BRIEF -->" in line:
            line = readme_file.readline()
            brief += line.rstrip('\n')
        line = readme_file.readline()
    readme_file.close()
    # If there was no BRIEF tag, returning module name to use as description.
    if len(brief) == 0:
        return module
    else:
        return brief

def generate_module_components(module_dir, component_list_dest_file, stash_base_url):
    # Adding markdown table headers, initialising markdown data as a list
    markdown_data = []
    markdown_row = "| module | charts | images | multiarch |"
    markdown_data.append(markdown_row)
    markdown_row = "|:-|:-|:-|:-|"
    markdown_data.append(markdown_row)

    # Adding every folder under modules to iterate over and sorting it
    module_list = os.listdir(path=module_dir)
    module_list.sort()

    # One module per row of markdown
    for module in module_list:
        # Adding module name to first column
        markdown_row = "| " + module_to_url(module, stash_base_url) + " | "
        # Adding module's charts (see the function for details)
        markdown_row += list_charts(module, module_dir) + " | "
        # Adding module's images (see the function for details)
        markdown_row += list_images(module, module_dir) + " |"
        # Checking if module is multiarch
        markdown_row += is_multiarch(markdown_row) + " |"
        # Adding the completed row to our list
        markdown_data.append(markdown_row)
    try:
        markdown_file = open(component_list_dest_file, "w+")
    except:
        print("Could not update " + component_list_dest_file)
        quit()
    for row in markdown_data:
        markdown_file.write(row + "\n")
    markdown_file.close()
    return

def generate_module_list(module_dir):
    base_url = module_dir
    markdown_data = []
    markdown_row = "| module | brief description |"
    markdown_data.append(markdown_row)
    markdown_row = "|:-|:-|"
    markdown_data.append(markdown_row)
    # Adding every folder under modules to iterate over and sorting it
    module_list = os.listdir(path=module_dir)
    module_list.sort()
    # One module per row of markdown
    for module in module_list:
        # Adding module name to first column
        markdown_row = "| " + module_to_url(module, base_url) + " | "
        # Fetching brief description from README.md
        markdown_row += get_brief(module, module_dir) + " | "
        markdown_data.append(markdown_row)
    return markdown_data

def add_table_to_readme(readme_path, module_table):
    try:
        readme_file = open(readme_path)
    except FileNotFoundError:
        return
    # If file could be accessed, loading it as a long string
    readme_data = "".join(readme_file.readlines())
    readme_file.close()
    # Splitting the long string from TABLEMARKER tags
    readme_data = readme_data.split("<!-- TABLEMARKER -->")
    # Joining the module_table list with newline characters
    module_table = "\n".join(module_table)
    # Replacing whatever was between TABLEMARKER tags with the module_table
    readme_data[1] = "\n" + module_table + "\n"
    # Stitching the readme back together using TABLEMARKER as the separator
    readme_data = "<!-- TABLEMARKER -->".join(readme_data)

    # Overwriting existing README
    try:
        markdown_file = open(readme_path, "w+")
        markdown_file.write(readme_data)
        markdown_file.close()
        print("Updated " + readme_path)
    except:
        print("Could not update "+ readme_path)
        quit()

if __name__ == "__main__":
    main()