This is the source code for the edX mobile iOS app. It is changing rapidly and
its structure should not be relied upon. See http://code.edx.org for other
parts of the edX code base.

License
=======
This software is licensed under version 2 of the Apache License unless
otherwise noted. Please see ``LICENSE.txt`` for details.

Building
========
1. Check out the source code: ::
    
    git clone https://github.com/edx/edx-app-ios

2. Open ``edXVideoLocker.xcworkspace``.

3. Ensure that the ``edXVideoLocker`` scheme is selected.

4. Click the **Run** button.

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


The full set of known keys can be found in the ``EDXConfig.m`` file.  These list the high-level keys; sub-keys can be found in the .m files for each config file.  These files are found in the Environment group in XCode.  (See COURSE_ENROLLMENT and SEGMENT_IO examples below.)

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

Here is a list of the graphic assets in this branch to replace if customizing the app (found in /edXVideoLocker):
    splash_start_lg.png
    splash(640x960).png
    splash9640x1136.png (<--mislabeled, but this is the filename)
    Splash_map.png
    bg_map.png
    map.png, map@2x.png
    logo.png, logo@2x.png, logo@3x.png

If you need to make more in depth UI changes, most of the user interface is
specified in the ``Main.storyboard`` file, editable from Interface Builder
within Xcode.

It is currently not possible to enroll for courses via the iOS app.  Until this is available, disable the course enrollment and tell the app where to send users via Safari in your yaml file:

::
    COURSE_ENROLLMENT:
        ENABLED: 'NO'
        EXTERNAL_COURSE_SEARCH_URL: 'http://<your.edx-platform.app.url>'

As mentioned, the app relies on the presence of several third party services:
Facebook, NewRelic, Google+, SegmentIO, and Crashlytics. To integrate your own SegmentIO key, enable segment io in edx-platform and set these in your iOS yaml file:
::
    SEGMENT_IO:
        ENABLED: 'YES'
        SEGMENT_IO_WRITE_KEY: '<yourSegmentIOKey>'

You can remove references to each of these services you choose not to use by commenting out the lines that mention these services. We're working to make those dependencies optional.


