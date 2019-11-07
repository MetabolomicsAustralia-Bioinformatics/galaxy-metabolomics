.. image:: https://readthedocs.org/projects/pip/badge/?version=latest
   :target: https://gxformat2.readthedocs.org

.. image:: https://badge.fury.io/py/gxformat2.svg
   :target: https://pypi.python.org/pypi/gxformat2/

.. image:: https://travis-ci.org/jmchilton/gxformat2.png?branch=master
   :target: https://travis-ci.org/jmchilton/gxformat2

.. image:: https://coveralls.io/repos/jmchilton/gxformat2/badge.svg?branch=master
   :target: https://coveralls.io/r/jmchilton/gxformat2?branch=master


This package defines a high-level Galaxy_ workflow description termed "Format
2". At this point, these workflows are defined entirely client side and
transcoded into traditional (or Format 1?) Galaxy workflows.

The traditional Galaxy workflow description is not meant to be concise and is
neither readily human readable or human writable. Format 2 addresses all three
of these limitations.

Format 2 workflow is a highly experimental format and will change rapidly in
potentially backward incompatible ways until the code is merged into the
Galaxy server and enabled by default.

* Free software: Academic Free License version 3.0
* Documentation: https://galaxy-lib.readthedocs.org.
* Code: https://github.com/galaxyproject/galaxy-lib


.. _Galaxy: http://galaxyproject.org/
.. _GitHub: https://github.com/
.. _Travis CI: http://travis-ci.org/




History
-------

.. to_doc

---------------------
0.9.0 (2019-07-08)
---------------------

* Implement default values in gxformat2.

---------------------
0.8.4 (2019-06-24)
---------------------

* Fix output IDs of 0.    

---------------------
0.8.3 (2019-05-23)
---------------------

* Implement set_columns PJA.

---------------------
0.8.2 (2019-03-16)
---------------------

* Allow another API return option for experimental tool creation API.

---------------------
0.8.1 (2019-03-11)
---------------------

* Implement change datatype PJA.

---------------------
0.8.0 (2018-11-01)
---------------------

* Implement experimental CWL-style step defaults (see Galaxy PR #6850).

---------------------
0.7.1 (2018-10-09)
---------------------

* Various small fixes for changes in 0.7.1.

---------------------
0.7.0 (2018-10-08)
---------------------

* Add some basic test cases.
* Allow ID-map style listing of steps.
* Ordered load (in addition to existing dump functionality) or ordering of steps in ID-map style variant works.
* Allow CWL-style $graph defs that can define multiple workflows in a single file.
* Initial work on de-duplicating subworkflow definitions on import.
* Fix position handling while exporting workflow.

---------------------
0.6.1 (2018-10-01)
---------------------

* Fix export of non-data parameters and implicit workflow connections.

---------------------
0.6.0 (2018-10-01)
---------------------

* Various fixes, allow id map style workflow input definitions.

---------------------
0.5.0 (2018-10-01)
---------------------

* More fixes for PJA, add the ``doc`` keyword to format 2 workflows to match CWL workflows. Map to and from native Galaxy workflows as annotations.

---------------------
0.4.0 (2018-10-01)
---------------------

* Fixes for exporting PJA when exporting workflows from native .ga to format 2.

---------------------
0.3.2 (2018-10-01)
---------------------

* Fixes for exporting workflow outputs from native .ga to format 2, support for modern map style output definitions like CWL 1.0.

---------------------
0.3.1 (2018-10-01)
---------------------

* Fixes for exporting subworkflows from native .ga to format 2.

---------------------
0.3.0 (2018-09-30)
---------------------

* More cwl style inputs, initial work on conversion from native workflows, various small fixes and tweaks.

---------------------
0.2.0 (2018-02-21)
---------------------

* Bring in latest Galaxy updates - Python 3 fixes, safe YAML usage, and more PJA implemented.

---------------------
0.1.1 (2016-08-15)
---------------------

* Fix one Python 3 incompatibility.

---------------------
0.1.0 (2016-05-02)
---------------------

* Initial version - code from Galaxy's test framework with changes
  based on planemo testing.


