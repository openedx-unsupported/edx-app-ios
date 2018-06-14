This is the source code for the edX mobile iOS app. It is changing rapidly and
its structure should not be relied upon. See http://code.edx.org for other
parts of the edX code base.

It requires the "Dogwood" release of open edX or newer. See
https://openedx.atlassian.net/wiki/display/COMM/Open+edX+Releases for more
information.

License
=======
This software is licensed under version 2 of the Apache License unless
otherwise noted. Please see ``LICENSE.txt`` for details.

Building
========
1. Check out the source code: ::
    
    git clone https://github.com/edx/edx-app-ios

2. Open ``edX.xcworkspace``.

3. Ensure that the ``edX`` scheme is selected.

4. Click the **Run** button.

*Note: Our build system requires Java 7 or later.  If you see an error
mentioning "Unsupported major.minor version 51.0 " then you should install a
newer Java SDK.*

Configuration
=============
The edX mobile iOS app is designed to connect to an Open edX instance. You must
configure the app with the correct server address and supply appropriate OAuth
credentials. We use a configuration file mechanism similar to that of the Open
edX platform.  This mechanism is also used to make other values available to
the app at runtime and store secret keys for third party services.

There is a default configuration that points to an edX devstack instance
running on localhost. See the ``default_config`` directory. For the default
configuration to work, you must add OAuth credentials specific to your
installation.

Setup
-----
To use a custom configuration in place of the default configuration, you will need to complete these tasks:

1. Create your own configuration directory somewhere else on the file system.
For example, create ``my_config`` as a sibling of the ``edx-app-ios`` repository.

2. Create an ``edx.properties`` file at the top level of the ``edx-app-ios``
repository. In this ``edx.properties`` file, set the ``edx.dir`` property to the
path to your configuration directory. For example, if I stored my configuration
at ``../my_config`` then I'd have the following ``edx.properties``:

::

    edx.dir = '../my_config'

3.  In the configuration directory that you added in step 1, create another
``edx.properties`` file.  This properties file contains a list of filenames.
The files should be in YAML format and are for storing specific keys. These
files are specified relative to the configuration directory. Keys in files
earlier in the list will be overridden by keys from files later in the list.
For example, if I had two files, one shared between iOS and Android called
``shared.yaml`` and one with iOS specific keys called ``ios.yaml``, I would
have the following ``edx.properties``:

::

    edx.ios {
        configFiles = ['shared.yaml', 'ios.yaml']
    }


The full set of known keys can be found in the ``OEXConfig.m`` or see
`additional documentation <https://openedx.atlassian.net/wiki/display/MA/App+Configuration+Flags>`_.

Additional Customization
------------------------
Right now this code is constructed specifically to build the *edx.org* app.
We're working on making it easier for Open edX installations to apply
customizations and select third party services without modifying the repository
itself. Until that work is complete, you will need to modify or replace files
within your fork of the repo.

To replace the edX branding you will need to replace the ``appicon`` files.
These come in a number of resolutions. See Apple's documentation for more
information on different app icon sizes. Additionally, you will need to replace
the ``splash`` images used in the login screen.

If you need to make more in depth UI changes, most of the user interface is
specified in the ``Main.storyboard`` file, editable from Interface Builder
within Xcode.

As mentioned, the app relies on the presence of several third party services:
Facebook, NewRelic, Google+, SegmentIO, and Crashlytics. You must remove references to each of these services you choose not to use. You can comment out the lines that mention these services. We're working to make those dependencies optional.

Whitelabel Script
-----------------

1. Checkout a new branch for your app, e.g. ::

    git checkout -b my-new-app

2. Reset to the desired base upstream ref, e.g. ::

    git reset --hard master

3. Create a virtualenv for use with the ``whitelabel`` script, and install dependencies.
   Either Python2.7 or Python3.x will work. ::

    virtualenv edx-app-ios
    source edx-app-ios/bin/activate
    pip install pyyaml

4. In a separate dir, create your whitelabel configuration file, e.g. ``../my-app-config/whitelabel.yaml``
   Run the ``whitelabel`` script to see the options: ::

    python script/whitelabel.py --help
    python script/whitelabel.py --help-config-file

5. In that separate dir, optionally create your resource directory and files.  e.g., to update the colors.json file: ::

    mkdir -p ../my-app-config/Resources/Colors
    cp Source/Resources/Colors/colors.json ../my-app-config/Resources/Colors/
    # edit ../my-app-config/Resources/Colors/colors.json as required

6. Run the `whitelabel.py` script to apply your whitelabel changes to the current branch. ::

    python script/whitelabel.py --config-file=../my-app-config/whitelabel.yaml -v
