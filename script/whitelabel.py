#!/usr/bin/env python
"""
Script to update the current edX iOS App with different names, resources, etc.

Requirements:

    pip install pyyaml
"""

import argparse
import logging
import os
import shutil
import subprocess
import sys

import yaml


class WhitelabelApp:
    """
    Update the current edX iOS App using configured resources and properties.
    """

    EXAMPLE_CONFIG_FILE = """
---
# Notes:
# * All configuration items are optional.
# * Use absolute paths if the property is not relative to the config_dir (or project_dir, for project_* properties).

# Path to your overridden project properties file, which may list your private project config files.
properties: 'edx.properties'

# Path to the Resources to override.  Omit to copy no resources.
resources: 'Resources'

# List of patch files to apply to the source. Omit to apply no patches.
patches:
    - patches/0001_update_text.patch
    - patches/0001_version.patch

# Update the iOS app properties (plist file):
plist:
    CFBundleName: 'MySchoolApp'
    CFBundleDisplayName: 'MySchoolApp'
    CFBundleSpokenName: 'My School App'
    FacebookDisplayName: 'MySchoolApp'
    CFBundleVersion: 2.6.1.6
    CFBundleIconFiles: !!null  # using null deletes the property.
    CFBundleIcons: !!null
    CFBundleIcons~ipad: !!null

# Path to the base dir containing your properties_file and resources dir.
# Defaults to the dir containing config file passed to this script.
config_dir: '/path/to/your/config/'

# You probably don't need to provide anything below this line.
# Defaults are as shown.

# Base dir of the project to update.
project_dir: '.'

# All project_ paths below can be relative to the project_dir

# Path to the application's plist file
project_plist: 'Source/edX-Info.plist'

# Path to the project's Resources dir
project_resources: 'Source/Resources'

# Path to the OSX utility command, PlistBuddy
plist_buddy = '/usr/libexec/PlistBuddy'

# Path to git
git_command = '/usr/bin/env git'
"""

    def __init__(self, **kwargs):

        # Config-relative paths
        self.config_dir = kwargs.get('config_dir')
        if not self.config_dir:
            self.config_dir = '.'

        # Assume that these paths are relative to config_dir.
        # (If 'properties' is absolute, then it will be unchanged by the path join)
        self.resources = kwargs.get('resources')
        if self.resources:
            self.resources = os.path.join(self.config_dir, self.resources)

        self.patches = []
        for patchfile in kwargs.get('patches', []):
            self.patches.append(os.path.join(self.config_dir, patchfile))

        # Project-relative paths
        self.project_dir = kwargs.get('project_dir')
        if not self.project_dir:
            self.project_dir = '.'

        self.project_resources = kwargs.get('project_resources')
        if not self.project_resources:
            self.project_resources = os.path.join(self.project_dir, 'Source', 'Resources')

        self.project_properties = kwargs.get('properties')
        if self.project_properties:
            self.project_properties = os.path.join(self.project_dir, self.project_properties)

        self.project_plist = kwargs.get('project_plist')
        if not self.project_plist:
            self.project_plist = os.path.join(self.project_dir, 'Source', 'edX-Info.plist')

        self.plist = kwargs.get('plist', {})

        self.plist_buddy = kwargs.get('plist_buddy')
        if not self.plist_buddy:
            self.plist_buddy = '/usr/libexec/PlistBuddy'

        self.git_command = kwargs.get('git_command')
        if not self.git_command:
            self.git_command = '/usr/bin/env git'

    def whitelabel(self):
        """
        Update the properties, resources, and configuration of the current app.
        """
        if self.apply_patches():
            self.create_project_properties()
            self.update_plist()
            self.copy_resources()
        else:
            logging.error("Update aborted until patches are repaired.")

    def create_project_properties(self):
        """
        Create a project .properties file that points to the config_dir file, if configured.
        """
        if self.project_properties and self.config_dir:
            logging.info("Creating %s", self.project_properties)
            content = "edx.dir = '{config_dir}'"
            with open(self.project_properties, 'w') as f:
                f.write(content.format(config_dir=self.config_dir))
        else:
            logging.debug("Not creating %s, properties or config_dir not set", self.project_properties)

    def update_plist(self):
        """
        Update the app's plist file.
        """
        for name, value in self.plist.items():
            if self._update_plist(name, value):
                logging.info("Updated %s: %s=%s", self.project_plist, name, value)
            else:
                logging.error("Error updating %s: %s=%s", self.project_plist, name, value)

    def copy_resources(self):
        """
        Copy over the existing resources files.
        """
        if self.resources:
            self._copytree(self.resources, self.project_resources)
        else:
            logging.debug("No resources to copy to %s", self.project_resources)

    def apply_patches(self):
        """
        Apply the given patches to the project source.
        """
        git_error = False
        for reference in self.patches:
            if git_error:
                logging.error("    %s", reference)
            elif not self._apply_patch(reference):
                git_error = True
                logging.error("Issue detected while applying patch %s. "
                              "Please fix the issue and manually apply the remaining patches:", reference)
        if not self.patches:
            logging.debug("No patches to apply")

        return not git_error

    def _copytree(self, src, dst, symlinks=False, ignore=None):
        """
        Recursively copy the files and dirs from src to dst.

        We can't use os.path.copytree here, because it balks if dst exists.
        """
        if not os.path.exists(dst):
            os.makedirs(dst)
        for item in os.listdir(src):
            s = os.path.join(src, item)
            d = os.path.join(dst, item)
            if os.path.isdir(s):
                self._copytree(s, d, symlinks, ignore)
            else:
                logging.info("Copying %s to %s", s, d)
                shutil.copy2(s, d)

    def _update_plist(self, name, value):
        """Update the app .plist file using PlistBuddy"""
        cmd = 'Delete' if value is None else 'Set'
        command = '{cmd} :{name} {value}'.format(cmd=cmd, name=name, value=value)
        call_args = self.plist_buddy.split(' ') + ['-c', command, self.project_plist]
        return self._system_command(call_args)

    def _apply_patch(self, filename):
        """Apply the given patch using a 3-way merge."""
        call_args = self.git_command.split(' ') + ['apply', '--3way', filename]
        return self._system_command(call_args)

    @staticmethod
    def _system_command(call_args):
        """Make the given subprocess call, and pipe output/errors to logger."""
        logging.debug("System call: %s", " ".join(call_args))
        process = subprocess.Popen(call_args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        (output, error) = process.communicate()
        if output:
            logging.info(output)
        if error:
            logging.error(error)
        return process.returncode == 0


def main():
    """
    Parse the command line arguments, and pass them to WhitelabelApp.
    """
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--help-config-file', action='store_true', help="Print out a sample config-file, and exit")
    parser.add_argument('--config-file', '-c', help="Path to the configuration file")
    parser.add_argument('--verbose', '-v', action='count', help="Enable verbose logging. Repeat -v for more output.")
    args = parser.parse_args()

    if args.help_config_file:
        print(WhitelabelApp.EXAMPLE_CONFIG_FILE)
        sys.exit(0)

    if not args.config_file:
        parser.print_help()
        sys.exit(1)

    log_level = logging.WARN
    if args.verbose > 0:
        log_level = logging.INFO
    if args.verbose > 1:
        log_level = logging.DEBUG
    logging.basicConfig(level=log_level)

    with open(args.config_file) as f:
        config = yaml.load(f) or {}

    # Use the config_file's directory as the default config_dir
    config.setdefault('config_dir', os.path.dirname(args.config_file))

    whitelabeler = WhitelabelApp(**config)
    whitelabeler.whitelabel()


if __name__ == "__main__":
    main()
